class Report < ActiveRecord::Base
  has_many :fields_reports, :order => 'location, seq_no', :dependent => :destroy
  has_many :report_requests, :order => 'name', :dependent => :destroy
  has_many :field_report_filters, :order => 'reference_screen_index', :dependent => :destroy
  
  serialize :reference_screen_ids
  serialize :reference_screen_alias
  serialize :criterias
  serialize :reference_screen_outer_joins
  serialize :grand_total

  class << self
    def criteria_operations
      ['==', '!=', '<', '<=', '>', '>=']
    end

    def grand_total_locations
      FieldsReport.locations - [:cell]
    end

  end

  # Force unloading un-cached associations
  def reload_uncached_association
    self.fields_reports.each{|fr| fr.reload_uncached_association } if self.fields_reports.loaded?
    self.field_report_filters.each{|frf| frf.reload_uncached_association } if self.field_report_filters.loaded?

    self.report_requests.reload if self.report_requests.loaded?
  end
  
  FieldsReport.locations.each do |l|
    eval <<LOCATION_FIELD_REPORTS
    def #{l}_fields_reports
      @#{l}_fields_reports ||= nil

      unless @#{l}_fields_reports
        @#{l}_fields_reports = fields_reports.select{|fr| fr.location == :#{l} }
      end
      @#{l}_fields_reports
    end

    def #{l}_fields_report_ids
      @#{l}_fields_report_ids ||= nil

      unless @#{l}_fields_report_ids
        @#{l}_fields_report_ids = #{l}_fields_reports.collect{|fr| fr.id }
      end
      @#{l}_fields_report_ids
    end
LOCATION_FIELD_REPORTS
  end

  def reference_screen_ids
    self[:reference_screen_ids] ||= []
    self[:reference_screen_ids].collect{|id| id.to_i if id.to_i > 0}.compact
	end
  
  def reference_screens
    @reference_screens ||= []
    
    begin
      @reference_screens = reference_screen_ids.collect{|s_id| Screen.find(s_id)}
    end if !ActiveRecord::Base.instance_cached? or @reference_screens.empty?
    
    @reference_screens
  end

  def cell_location
    self[:cell_location] ||= :row
    self[:cell_location].to_sym
  end

  def visible_reference_screen_indexes
    @visible_reference_screen_indexes ||= self.row_fields_reports.collect{|rfr|
      rfr.reference_screen_index if rfr.summarize == :non
    }.compact.uniq
  end

  def is_screen_index_visible?(reference_screen_index)
    visible_reference_screen_indexes.include?(reference_screen_index)
  end

  def hide_row_columns?
    @hide_row_columns ||= self.row_fields_reports.any? do |rfr|
      self.is_screen_index_visible?(rfr.reference_screen_index)
    end
  end
  
  def has_percentage_weight?
    self.fields_reports.any?{|fr |fr.is_percentage_weight? }
  end

  def description
    if @description.nil?
      @description = self[:name]
    end

    @description
  end

  def row_field_report_screen_indexes
    @row_field_report_screen_indexes ||= row_fields_reports.collect{|fr| fr.reference_screen_index }.uniq
  end

  def fields_for_filters
    @fields_for_filters ||= {}
    
    reference_screens.each_with_index do |s, s_idx|
       data_fields = s.fields.select{|f| f.is_a?(Fields::Data)}
       @fields_for_filters[s_idx] = data_fields unless data_fields.empty?
    end if @fields_for_filters.empty?

    @fields_for_filters
  end

  def sorting_options
    @sorting_options ||= begin
      options = {
        :sorting => :none,
        :index => 0
      }

      field_report_sorting = self.fields_reports.select{ |fr| fr.sorting != :none }
      if !field_report_sorting.empty?
        options[:sorting] = field_report_sorting[0].sorting
        options[:location] = field_report_sorting[0].location
        fields_reports = self.fields_reports.select{ |fr| fr.location == options[:location] }

        options[:index] = fields_reports.index(field_report_sorting[0])

        if options[:location] == :cell
          options[:index] = fields_reports.length - options[:index]
        end
      end

      options
    end
  end

  def is_outer_join?(screen_index)
    @outer_join_value ||= {}
    @outer_join_value[screen_index] ||= CustomFields::CheckBox.true_or_false?(self.reference_screen_outer_joins[screen_index]['0'])
  end

  def display_chart?
    @display_chart ||= self.cell_fields_reports.any?{|fr| fr.chart_axis != :none }
  end

  def display_grand_totals
    @grand_totals ||= begin
      self[:grand_total] ||= Report.grand_total_locations
      self[:grand_total].collect{|gt| gt.to_sym }
    end
  end

  def allow_action?(action)
    self.fields_reports.collect do |fr| 
      case fr.field_type
      when :formula
        functions = Field.display_formula_control_options.collect{|opt| opt[:key].to_sym}
        ext_vals = Fields::Formula.hidden_field_value(fr.formula).select{|hdv| !functions.include?(hdv.to_sym)}
        
        ext_vals.collect do |ext_val|
          reference_screens[ext_val.split('|').last.to_i]
        end
      else
        reference_screens[fr.reference_screen_index]
      end      
    end.compact.flatten.uniq.all?{|screen| screen.allow_action?(action) }
  end

  validates_uniqueness_of :name
  validates_presence_of :name
  validates_presence_of :reference_screen_ids
  validates_length_of :remark, :within => 0..255
end

#~ Code for reordering screens and the related screen_indexes
#
#@new_reference_screen_ids = nil
#
#def reorder
#  {
#    'Monthly Sales Amount' => ['Business Record', 'Customer'],
#    'Monthly Sales Amount by Nation' => ['Nation', 'Customer', 'Business Record'],
#    'Monthly Sales Amount by Country' => ['Country', 'Customer', 'Business Record'],
#    'Monthly Sales Amount by Province' => ['Province', 'Customer', 'Business Record'],
#    'Monthly Sales Amount by Estate' => ['Industrial Estate', 'Customer', 'Business Record'],
#    'Monthly Sales Amount by Business Type' => ['Business Type', 'Customer', 'Business Record'],
#    'Monthly Sales Amount by Branch' => ['Sales Office', 'Staff', 'Business Record'],
#    'Half-Year Sales Amount by Nation' => ['Nation', 'Customer', 'Business Record'],
#    'Half-Year Sales Amount by Country' => ['Country', 'Customer', 'Business Record'],
#    'Half-Year Sales Amount by Province' => ['Province', 'Customer', 'Business Record'],
#    'Half-Year Sales Amount by Estate' => ['Industrial Estate', 'Customer', 'Business Record'],
#    'Half-Year Sales Amount by Business Type' => ['Business Type', 'Customer', 'Business Record'],
#    'Half-Year Sales Amount by Province & Customer' => ['Province', 'Customer', 'Business Record', 'Industrial Estate'],
#    'Half-Year Sales Amount by Province & Estate' => ['Province', 'Industrial Estate', 'Customer', 'Business Record'],
#    'Half-Year Sales Customer Count by Province and Estate' => ['Province', 'Industrial Estate', 'Customer', 'Business Record']
#  }
#end
#
#def new_reference_screen_index(report, reference_screen_index)
#  reference_screen_id = report.reference_screen_ids[reference_screen_index]
#  new_reference_screen_ids(report).index(reference_screen_id)
#end
#
#def new_reference_screen_ids(report)
#   new_reference_screen_names = reorder[report.name]
#   @new_reference_screen_ids ||= {}
#   @new_reference_screen_ids[report.name] ||= report.reference_screens.sort{|a,b|
#    new_reference_screen_names.index(a.name) <=> new_reference_screen_names.index(b.name)
#  }.collect{|s| s.id }
#end
#
#def new_reference_screen_alias(report)
#  report.reference_screen_alias.sort{|a,b|
#    new_reference_screen_index(report, report.reference_screen_alias.index(a)) <=> new_reference_screen_index(report, report.reference_screen_alias.index(b))
#  }
#end
#
#def reorder_reference_screens(report)
#  report.fields_reports.each do |fr|
#    fr.reference_screen_index = new_reference_screen_index(report, fr.reference_screen_index)
#
#    if fr.reference_screen_index
#      fr.save
#    else
#      fr.destroy
#    end
#  end
#
#  report.field_report_filters.each do |frf|
#    frf.reference_screen_index = new_reference_screen_index(report, frf.reference_screen_index)
#
#    if frf.reference_screen_index
#      frf.save
#    else
#      frf.destroy
#    end
#  end
#
#  report.report_requests.each do |rr|
#
#    rr.field_filters.each do |ff|
#      ff.reference_screen_index = new_reference_screen_index(report, ff.reference_screen_index)
#
#      if ff.reference_screen_index
#        ff.save
#      else
#        ff.destroy
#      end
#    end
#
#    rr.report_request_rows.each do |rrr|
#      rrr.destroy
#    end
#
#    rr.report_request_cols.each do |rrc|
#      rrc.destroy
#    end
#    rr.last_run_at = Date.null_date
#
#    rr.save
#  end
#
#  report.criterias.each do |c|
#    [:a, :b].each do |s|
#      c[:'#{s.to_s}reference_screen_index"] = new_reference_screen_index(report, c[:"#{s.to_s}reference_screen_index"])
#    end
#  end
#
#  report.reference_screen_alias = new_reference_screen_alias(report)
#  report.reference_screen_ids = new_reference_screen_ids(report)
#
#  report.save
#end
