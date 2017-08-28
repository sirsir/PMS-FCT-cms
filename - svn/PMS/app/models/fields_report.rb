class FieldsReport < ActiveRecord::Base
  belongs_to  :report
  belongs_to  :field
  belongs_to  :label
  has_many :report_request_cols, :order => 'id', :dependent => :destroy

  serialize :field_format
  serialize :percentage_weight
  serialize :formula

  class << self
    def summarize_options
      [:non, :auto, :cnt, :sum, :avg, :min, :max, :per, :grp, :unq]
    end

    def summarize_descriptions
      {
        :non => 'None',
        :auto => 'Auto',
        :cnt => 'Count',
        :sum => 'Sum',
        :avg => 'Average',
        :min => 'Minimum',
        :max => 'Maximum',
        :per => 'Percentage',
        :grp => 'Group',
        :unq => 'Unique'
      }
    end

    def locations
      [:row, :cell, :col]
    end

    def sortings
      [:none, :asc, :desc]
    end

    def chart_axises
      [:none, :left, :right]
    end
  end

  # Force unloading un-cached associations
  def reload_uncached_association
    if self.field_id > 0
      self.field.reload_uncached_association if self.field.loaded?

      Field.find(self.field_id).reload_uncached_association
    end
    
    self.report_request_cols.reload if self.report_request_cols.loaded?
  end

  def summarize
    @summarize ||= begin
      self[:summarize] ||= FieldsReport.summarize_options[0]
      
      self[:summarize].to_sym
    end
  end

  def location
    @location ||= begin
      self[:location] ||= FieldsReport.locations[0]

      self[:location].to_sym
    end
  end

  def field_type
    @field_type ||= begin
      self[:field_type] ||= :field

      self[:field_type].to_sym
    end
  end

  def descr
    @descr ||= begin
      feild_descr = case
      when !self.label.nil?
        self.label.descr
      when self.field_type == :formula
        Fields::Formula.evaluate_syntax(self.formula)
      when self.field_id < 0
        self.report.reference_screens[self.reference_screen_index].label_descr
      else
        self.field.descr
      end.strip

      fr_format = self.format

      if fr_format.is_a?(Hash) && fr_format.has_key?(:option)
        prefix = "#{fr_format[:option][:prefix_multiplier]}" if fr_format[:option].has_key?(:prefix_multiplier) && fr_format[:option][:prefix_multiplier].to_sym != :None
        currency = "#{fr_format[:option][:unit]}" if fr_format[:format].to_sym == :currency
        unit = " (#{prefix}#{currency})" unless prefix.nil? && currency.nil?
        feild_descr.gsub!(/^[^\(]?\(.+?\)$/, '') unless unit.nil?
      end

      "#{feild_descr}#{unit}"
    end
  end

  alias_method :full_descr, :descr

  def filter_name
    @filter_name ||= begin
      case self.field.custom_field
      when CustomFields::Reference then
        self.field.custom_field.screen.label_descr
      when CustomFields::ComboBox || CustomFields::RadioButton then
        self.field.custom_field.label_descr
      when CustomFields::LoginField  then
        'Staff'
      when CustomFields::DateTimeField then
        'Date'
      when CustomFields::IssueTracking then
        ''
      when CustomFields::ListBox then
      end
    end
  end

  def sorting
    self[:sorting_index] ||= 0
    @sorting ||= FieldsReport.sortings[self[:sorting_index].to_i]
  end

  def chart_axis
    @chart_axis ||= (location == :cell) ? FieldsReport.chart_axises[self[:chart_axis_index].to_i] : :none
  end

  def format
    @format ||= begin
      self.field_format ||= {}
      self.field_format[:format] ||= {}
      
      case self.field_type
      when :formula
        self.field_format[:format][:format] ||= :number
        self.field_format[:format][:format] = self.field_format[:format][:format].to_sym
        CustomFields::NumericField.validate_custom_field_value(self.field_format[:format], self.field_format[:format][:option])
      else
        field = self.field
        case field
        when Fields::Data
          cf = self.field.custom_field if self.field
          case cf
          when CustomFields::NumericField
            self.field_format[:format][:format] ||= self.field.custom_field.format
            CustomFields::NumericField.validate_custom_field_value(self.field_format[:format], self.field.custom_field.option)
          end
        when Fields::Formula
          self.field_format[:format][:format] ||= self.field.format
          CustomFields::NumericField.validate_custom_field_value(self.field_format[:format], self.field.option)  if self.field_format[:format][:format].to_sym == :number
        end
      end      
      
      self.field_format[:format]
    end
  end

  def format_data_type
    @format_data_type ||= begin
      self.format[:data_type] ||= :number

      self.format[:data_type].to_sym
    end
  end

  def is_percentage_weight?
    @percentage_weight ||= CustomFields::CheckBox.true_or_false?(self[:percentage_weight]['0'])
  end
  
  def percentage_weight_col_span
    @percentage_weight_col_span ||= 0
    @percentage_weight_col_span = 1 if self.location == :cell && self.is_percentage_weight?

    @percentage_weight_col_span
  end
  
  def row_cell_values(report_request_row, report_request_col, report_request_rows, options = {})
    defaults = {      
      :grand_total_row => false,
      :report_request_col_id => 0,
      :cell_value_cache => {},
      :show_percentage => false
    }
    options = defaults.merge(options)
    
    if options[:grand_total_row]
      case self.field_type
      when :formula
        formula_rrc = ReportRequestCols::FormulaSrc.new
        formula_rrc.id = options[:report_request_col_id]
        formula_rrc.fields_report = self
        
        report_request_cols = [formula_rrc]
      else
        if report_request_col.nil?
          report_request_cols = ReportRequestCol.find(:all,
            :conditions => {
              :report_request_cols => { 
                :report_request_id => report_request_row.report_request_id, 
                :report_request_col_id => nil            
              }
            }
          )      
        else
          report_request_cols = report_request_col.childs
        end
        
        report_request_cols = [report_request_cols.last] if report_request_cols.last.is_a?(ReportRequestCols::DateSrc)
        
        unless report_request_cols.empty?
          field_report_ids = report_request_cols.collect{|rrc| rrc.fields_report_id }.uniq
          
          while !field_report_ids.include?(self.id) && !field_report_ids.empty? do
            report_request_cols = report_request_cols.collect do |rrc|
              rrc.childs.select do |c|
                !c.is_a?(ReportRequestCols::DateSrc) || c.source_id == CustomFields::DateTimeField.month(:year)
              end
            end.flatten
            field_report_ids = report_request_cols.collect{|rrc| rrc.fields_report_id }.uniq
          end
          
          report_request_cols = report_request_cols.select{|rrc| rrc.fields_report_id == self.id }
        end
      end      
    else
      report_request_cols = [report_request_col]
    end
    
    cell_values = []
    cell_values << row_cell_value(report_request_row, report_request_cols, report_request_rows, options)
    cell_values_per = if self.is_percentage_weight?
      value = ReportRequestCell.evaluate(cell_values.first)
      grand_total_value = report_request_cols.flatten.collect{|c| c.grand_total_value}.compact.sum
      
      { :summarize => :per, :value => value, :grand_total_value => grand_total_value }
    elsif (self.location == :cell && self.report.cell_location == :row && options[:show_percentage])
      { :summarize => :per, :value => nil, :grand_total_value => 0.0 }
    end
    
    if self.report.cell_location == :col
      cell_values << cell_values_per unless cell_values_per.nil?
    elsif options[:show_percentage]
      cell_values = []
      cell_values << cell_values_per
    end
    
    cell_values
  end
  
  def row_cell_value(report_request_row, report_request_cols, report_request_rows, options)
    ht_cell_value = options[:cell_value_cache] || {}
    ht_cell_value[report_request_row.id] ||= {}
    
    report_request_col_id = options[:report_request_col_id]
    
    case self.field_type
    when :formula      
      cell_value = if report_request_row.id == 0 && self.summarize != :non
        report_request_rows.collect do |rrr|
          report_request_cols.collect do |rrc|
            formula_cell_values = rrc.evaluate_value(rrr, :row_cell_value => ht_cell_value)
            
            {:summarize => self.summarize, :values => [formula_cell_values]}
          end
        end.flatten.compact
      else
        report_request_cols.collect do |rrc|
          formula_cell_values = rrc.evaluate_value(report_request_row, :row_cell_value => ht_cell_value)
          
          {:summarize => self.summarize, :values => [formula_cell_values]}
        end.flatten.compact
      end
      
      ht_cell_value.delete(report_request_row.id) if report_request_row.id == 0
    else  
      cell_value = report_request_rows.collect do |rrr|
        report_request_cols.collect do |rrc|
          ht_cell_value[rrr.id] ||= {}
          ht_cell_value[rrr.id][rrc.id] ||=  rrr.cell(rrc.id).value if rrr.cell(rrc.id)
        end
      end.flatten.compact
      
      if options[:grand_total_row]
        ht_cell_value[report_request_row.id][report_request_col_id] ||= {}
        ht_cell_value[report_request_row.id][report_request_col_id]["#{self.field_id}|#{self.reference_screen_index}"] ||= cell_value        
      else
        report_request_cols.each{|rrc| ht_cell_value[report_request_row.id][rrc.id] ||= cell_value }
      end      
    end
    
    cell_value
  end

  validates_uniqueness_of :seq_no, :scope => [:report_id, :location]
end
