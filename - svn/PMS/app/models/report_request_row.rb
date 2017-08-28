class ReportRequestRow < ActiveRecord::Base
  belongs_to :report_request
  belongs_to :row
  has_many :report_request_cells, :after_add => :load_cell_hash, :dependent => :destroy
  belongs_to :report_request_row
  has_many :report_request_rows, :include => [:report_request_rows], :dependent => :destroy

  alias_attribute :parent ,:report_request_row
  alias_attribute :childs ,:report_request_rows

  alias_attribute :parent_id, :report_request_row_id
  alias_attribute :child_ids, :report_request_row_ids

  attr_internal_accessor :cell_hash

  class << self
    def purge(report_request_id)
      conn = ActiveRecord::Base.connection
      conn.delete <<SQL_CMD
DELETE FROM report_request_rows WHERE report_request_id = #{report_request_id}
SQL_CMD
    end
  end

  def load_cell_hash(report_request_cell=nil)
    if report_request_cell.nil?
      @cell_hash = {}
      report_request_cells.each {|c| @cell_hash[c.report_request_col_id] = c}
    else
      @cell_hash ||= {}
      @cell_hash[report_request_cell.report_request_col_id] = report_request_cell
    end
  end

  def cell(report_request_col_id)
    load_cell_hash unless !@cell_hash.nil? and !@cell_hash[report_request_col_id].nil?
    @cell_hash[report_request_col_id]
  end

  def summarize(fields_report)
    self.send :"summarize_#{fields_report.location}", fields_report
  end

  def description
    @description ||= row.nil? ? 'Grand Total' : row.description
  end

  def full_descr
    unless @full_descr
      fs = []
      fs << [self.parent.full_descr] unless self.parent.nil?
      fs << [self.descr]

      @full_descr = fs.join(' - ')
    end
    
    @full_descr
  end

  alias_method :descr, :description

  def visible?
    @is_visible ||= report_request.report.is_screen_index_visible?(self[:reference_screen_index])
  end

  def visible_child_ids
    unless @visible_child_ids
      if childs.empty?
        @visible_child_ids = []
      else
        if report_request.report.is_screen_index_visible?(childs.first.reference_screen_index)
          @visible_child_ids = childs.collect{|rrr| rrr.id }
        else
          @visible_child_ids = childs.collect{|rrr| rrr.visible_child_ids }.flatten
        end
      end
    end

    @visible_child_ids
  end
  
  def level
    unless @level
      @level = 1
      @level += parent.level if parent
    end
    
    @level
  end

  def row_span
    @row_span ||= self.childs.collect{|c| c.visible? ? c.row_span : 0 }.sum + 1
  end

  def leaf_report_request_rows
    unless @leaf_report_request_rows
      if childs.empty?
        @leaf_report_request_rows = [self]
      else
        @leaf_report_request_rows = childs.collect{|c| c.leaf_report_request_rows }.flatten
      end
    end

    @leaf_report_request_rows
  end

  def sorted_visible_report_request_rows(options={})
    unless @sorted_rows
      if childs.empty?
        @sorted_rows = []
      else
        index = options[:index]

        index = childs[0].cell_values.length - index unless options[:location] == :row
        
        childs.sort! do |a,b|
          if options[:location] == :row
            a_values = a.row_values
            b_values = b.row_values
          else
            a_values = a.cell_values
            b_values = b.cell_values
          end
          
          a_value = a_values[index][:value]
          b_value = b_values[index][:value]
          
          result = case
          when a_value.nil? then 1
          when b_value.nil? then -1
          else a_value <=> b_value
          end

          result *= -1 unless options[:sorting] == :asc || a_value.nil? || b_value.nil?

          result
        end.flatten

        @sorted_rows = childs.collect{|c| [c, c.sorted_visible_report_request_rows(options)]}.flatten
      end
    end

    @sorted_rows
  end

  def values(options = {})
    row_values(options) + cell_values(options)
  end
  
  def row_values(options = {})
    default = {
      :all_fields => false,
      :row_field_report => nil,
      :null_value => ''
    }
    opt = default.merge(options)
    
    @row_values ||= {}
    
    unless @row_values[opt]
      rfr_s_idxs = self.report_request.report.row_field_report_screen_indexes
      row_fields_reports = opt[:row_field_report] ? [opt[:row_field_report]] : self.report_request.report.row_fields_reports
      
      @row_values[opt] = row_fields_reports.collect do |rfr|
        row_span = 1
        unless self.new_record?
          own_field = rfr.reference_screen_index == self.reference_screen_index
          child_field = opt[:row_field_report].nil? && rfr_s_idxs.index(rfr.reference_screen_index) > rfr_s_idxs.index(self.reference_screen_index)
        end

        if own_field
          field = rfr.field
          
          row_span = self.row_span
          row_span = row_span * self.report_request.report.cell_fields_reports.size if self.report_request.report.cell_location == :row

          case field
          when Fields::Data
            unless field.custom_field_id.nil? || self.row.nil?
              actual_row = Field.row_by_field(field, self.row)
              cell = actual_row.cell(field.custom_field_id) unless actual_row.nil?
            end
            value = case cell.custom_field
            when CustomFields::NumericField
              cell.value.to_f
            else
              cell.to_text 
            end unless cell.nil?
          when Fields::DetailInfo
            field_detail_screen_value = field.get_detail_screen_value(field.detail_screen, self.row)

            value = field_detail_screen_value.size == 0 ? nil : field_detail_screen_value
          when Fields::HeaderInfo,
              Fields::Formula,
              Fields::Accumulation,
              Fields::Comparison,
              Fields::ReferenceAttribute,
              Fields::CodeCombindedReferenceAttribute

            value = field.evaluate_value(self.row)
          end
        elsif child_field
          value = summarize(rfr)
        elsif opt[:all_fields] && parent
          value = parent.row_values(
            :all_fields => true,
            :row_field_report => rfr
          ).compact.flatten.first[:value]
        end

        field_report_format = rfr.format

        format = if !field_report_format.nil? && !field_report_format[:option].nil?
          if field_report_format[:format] == 'percentage'
            :percentage
          elsif field_report_format[:option][:precision] > 0
            :number_pre2
          else
            :number
          end
        else
          :text
        end

        val_box = value_box(value.to_s.strip.empty? ? opt[:null_value] : value, :row, format)
        val_box[:row_span] = row_span
        val_box[:col_span] = 1
        val_box
      end
    end

    @row_values[opt]
  end

  def cell_values(options = {})
    default = {
      :report_request_col => nil,
      :report_request_col_ids => []
    }
    opt = default.merge(options)

    @cell_values ||= {}
    
    unless @cell_values[opt]
      report_request_col = opt[:report_request_col]
      report_request_col_ids = opt[:report_request_col_ids]

      if report_request_col.nil?
        col_field = self.report_request.report.col_fields_reports.first
        rrc_groups = self.report_request.col_report_request_cols(col_field)
        rrc_groups[0]
        values = rrc_groups[0].collect{|rrc| cell_values(:report_request_col => rrc) }
        values += self.report_request.report.cell_fields_reports.collect{|cfr| sub_total_value_box(cfr) } if self.report_request.report.display_grand_totals.include?(:col)
      else
        col_field = report_request_col.fields_report

        if col_field != self.report_request.report.col_fields_reports.last
          rrc_ids = report_request_col_ids + [report_request_col.id]

          values = report_request_col.childs.collect{|rrc| cell_values(:report_request_col => rrc, :report_request_col_ids => rrc_ids) }
          values += self.report_request.report.cell_fields_reports.collect{|cfr| sub_total_value_box(cfr, report_request_col) } if col_field.summarize != :non
        else
          values = report_request_col.childs.collect{|rrc| cell_value_box(rrc) }
        end
      end

      @cell_values[opt] = values.flatten
    end

    @cell_values[opt]
  end

  def field_cache
    @field_cache ||= {}
  end

  private
  
  def cell_value_box(report_request_col)
    rows = self.leaf_report_request_rows

    values = report_request_col.fields_report.row_cell_values(self, 
                                                              report_request_col, 
                                                              rows)

    field_report_format = report_request_col.fields_report.format
    
    format = if !field_report_format.nil? && !field_report_format[:option].nil?
      if field_report_format[:format] == 'percentage'
        :percentage
      elsif field_report_format[:option][:precision] > 0
        :number_pre2
      else
        :number
      end
    else
      :text
    end

    ht_cell_value_box = value_box(values.first, :cell, format)
    
    if !field_report_format.nil? && !field_report_format[:option].nil?
      if !field_report_format[:option][:prefix_multiplier].nil? && field_report_format[:option][:prefix_multiplier].to_sym != :None
        prefix_multiplier_value = 10**3
        prefix_multiplier_value = 10**6 if field_report_format[:option][:prefix_multiplier].to_sym == :M

       ht_cell_value_box[:value] = ht_cell_value_box[:value].to_f / prefix_multiplier_value
      end
    end

    if report_request_col.fields_report.is_percentage_weight?
      ht_percentage_value_box = value_box(values.last, :cell, :number_pre2)
      
      return ht_cell_value_box, ht_percentage_value_box
    else
      return ht_cell_value_box
    end
  end

  def sub_total_value_box(cell_field_report, report_request_col = nil)
    if report_request_col
      report_request_cols = [report_request_col]
    else
      report_request_cols = self.report_request.report.col_fields_reports.first.report_request_cols.select{|c| !c.is_a?(ReportRequestCols::DateSrc) || c.source_id == CustomFields::DateTimeField.month(:year)}
    end

    report_request_cols = report_request_cols.collect{|rrc| rrc.leaf_report_request_cols(true) }.flatten    
    report_request_cols = report_request_cols.select{|rrc| rrc.fields_report_id == cell_field_report.id }
    
    report_request_rows = self.leaf_report_request_rows
    report_request_col_id = ( report_request_col.nil? ) ? 0 : report_request_col.id
    
    ht_cell_value = {}
    
    case cell_field_report.field_type
    when :formula      
      report_request_col_childs = report_request_cols.collect{|rrc| rrc.parent.childs}.flatten
      report_request_col_childs = report_request_col_childs.select{|c| c.fields_report.field_type != :formula }
      
      report_request_rows.each do |rrr|
        report_request_col_childs.each do |c|
          field_id = c.fields_report.field_id
          reference_screen_index = c.fields_report.reference_screen_index
          
          ht_cell_value[rrr.id] ||= {}
          ht_cell_value[rrr.id][report_request_col_id] ||= {}
          ht_cell_value[rrr.id][report_request_col_id]["#{field_id}|#{reference_screen_index}"] ||= []
          
          if rrr.cell(c.id)
            ht_cell_value[rrr.id][report_request_col_id]["#{field_id}|#{reference_screen_index}"] ||= []
            ht_cell_value[rrr.id][report_request_col_id]["#{field_id}|#{reference_screen_index}"] << rrr.cell(c.id).value 
          end
        end  
      end
    else
      report_request_rows.each do |rrr|
        report_request_cols.each do |rrc|
          ht_cell_value[rrr.id] ||= {}
          ht_cell_value[rrr.id][rrc.id] ||= []
          
          if rrr.cell(rrc.id)
            ht_cell_value[rrr.id][rrc.id] ||= []
            ht_cell_value[rrr.id][rrc.id] << rrr.cell(rrc.id).value
          end          
        end
      end
    end
    
    options = { 
      :grand_total_row => true, 
      :report_request_col_id => report_request_col_id, 
      :cell_value_cache => ht_cell_value       
    }
    values = cell_field_report.row_cell_values(self, report_request_col, report_request_rows, options)

    field_report_format = report_request_col.fields_report.format unless report_request_col.nil?

    format = if !field_report_format.nil? && !field_report_format[:option].nil?
      if field_report_format[:format] == 'percentage'
        if self.new_record?
          :grand_total_percentage
        else
          :sub_total_percentage
        end
      elsif field_report_format[:option][:precision] > 0
        if self.new_record?
          :grand_total_number_pre2
        else
          :sub_total_number_pre2
        end
      end
    else
      :text
    end
    
    ht_sub_total_value_box = value_box(values.first, (self.new_record?) ? :grand_total : :sub_total, format )

    if !field_report_format.nil? && !field_report_format[:option].nil?
      if !field_report_format[:option][:prefix_multiplier].nil? && field_report_format[:option][:prefix_multiplier].to_sym != :None
        prefix_multiplier_value = 10**3
        prefix_multiplier_value = 10**6 if field_report_format[:option][:prefix_multiplier].to_sym == :M

       ht_sub_total_value_box[:value] = ht_sub_total_value_box[:value].to_f / prefix_multiplier_value
      end
    end

    if cell_field_report.is_percentage_weight?      
      type, format = if self.new_record?
        [:grand_total, :grand_total_number_pre2]
      else
        [:sub_total, :sub_total_number_pre2]
      end
      ht_percentage_value_box = value_box(values.last, type, format)
      
      return ht_sub_total_value_box, ht_percentage_value_box
    else
      return ht_sub_total_value_box
    end
  end

  def value_box(cell_values, value_type, value_format)
    {
      :value => value_type == :row ? cell_values : ReportRequestCell.evaluate(cell_values),
      :type => value_type,
      :format => value_format
    }
  end

  def summarize_row(fields_report)
    field = fields_report.field
    if !row.nil? && fields_report.reference_screen_index == reference_screen_index
      case field
      when Fields::Data then
        actual_row = Field.row_by_field(field, row)
        cell = actual_row.cell(field.custom_field_id) unless actual_row.nil?
        if cell
          absolute_value = cell.absolute_value
          case field.custom_field
          when CustomFields::Reference
            value = cell.to_text
          when CustomFields::CheckBox
            value = absolute_value.collect do |h|
              h.collect do|k, v|
                k.descr if v
              end
            end.flatten.compact
          when CustomFields::AutoNumbering
            value = cell.to_text
          else
            case absolute_value
            when String, DateTime, Date, Fixnum, Float, NilClass, TrueClass, FalseClass
              value = absolute_value
            when Label
              value = absolute_value.descr
            when Array
              value = absolute_value.collect do |v|
                case v
                when Row then
                  v.description
                when Label then
                  v.descr
                else
                  raise "Please determine how to summarizing #{v.class} #{v.to_yaml}"
                end
              end
            else
              raise "Please determine how to summarizing #{absolute_value.class} #{absolute_value.to_yaml}"
            end
          end
          
          if fields_report.summarize == :cnt
            value = 1 if !value.is_a?(Array) || !value.empty?
          end
        end
      else
        value = field.evaluate_value(row)
      end
    else
      summarize_fnc = fields_report.summarize
      unless summarize_fnc == :non
        rfr = fields_report.clone
        rfr[:summarize] = :val if summarize_fnc == :avg

        values = childs.collect{|c| c.summarize(rfr)}.flatten

        if !values.empty? or summarize_fnc == :cnt

          if [:cnt, :avg].include?(summarize_fnc)
            size = values.size
          end

          unless summarize_fnc == :val
            values.compact!
          end

          if [:sum, :avg].include?(summarize_fnc)
            values.collect!{|v| v.to_f }
          end

          case summarize_fnc
          when :cnt then
            value = size
          when :sum, :max, :min then
            value = values.send(summarize_fnc)
          when :avg then
            value = values.sum / size
          when :val then
            value = values
          when :grp
            value = values.first
          when :unq
            value = values.uniq
          end
        end
      end
    end
    
    value
  end

  validates_presence_of :report_request_id
  validates_presence_of :row_id
end
