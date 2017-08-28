require 'c_s_v_writer'

class ReportRequest < ActiveRecord::Base
  include CSVWriter
  include ExcelWriter
  include ActionView::Helpers::DateHelper

  belongs_to :report
  belongs_to :user
  
  has_many :field_filters, :after_add => :load_field_filter_hash, :dependent => :destroy
  has_many :report_request_rows, :dependent => :destroy
  has_many :report_request_cols, :dependent => :destroy
  has_many :parent_report_request_rows, :class_name => 'ReportRequestRow', :conditions => ['report_request_row_id is null']

  attr_internal_accessor :field_filter_hash

  alias_attribute :rows, :report_request_rows
  alias_attribute :cols, :report_request_cols
  
  class << self
    def request_methods
      [
        :request,
        :purge,
        :workflow_transition,
        :data_warehouse_etl,
        :save_columns,
        :filter_row_values,
        :remove_unreferred_rows,
        :check_row_relations,
        :sort_row_cols,
        :save_rows,
        :fetch_cell_values,
        :save_cells,
        :remove_unreferred_cols,
        :cache_chart_data
      ]
    end

    def request_message(request_method)
      {
        :request => nil,
        :purge => 'Delete previous request\'s results',
        :workflow_transition => 'Transition data through workflow',
        :data_warehouse_etl => 'Extract, transform and load data',
        :save_columns => 'Create cross-tab columns',
        :filter_row_values => 'Filter report records',
        :remove_unreferred_rows => 'Remove unreferred records',
        :check_row_relations => 'Check record\'s relations',
        :sort_row_cols => 'Sort report columns',
        :save_rows => 'Create report records',
        :fetch_cell_values => 'Fetch cross-tab values',
        :save_cells => 'Create cross-tab values',
        :remove_unreferred_cols => 'Remove unreferred columns',
        :cache_chart_data => 'Fetch charts data'
      }[request_method].to_s
    end

    def refresh_intervals
      [
        :off,
        :every_1_hour,
        :every_3_hours,
        :every_6_hours,
        :every_12_hours,
        :every_day,
        :alternately_day,
        :once_per_week,
        :once_per_month,
        :every_3_months,
        :every_6_months,
        :once_per_year
      ]
    end
    
    def export_formats
      {
        :xls => 'Microsoft Excel Workbook (*.xls)',
        :csv => 'Comma Separated Value (*.csv)'
      }
    end

    def background_colors_24bit
      @@background_colors_24bit ||= {
        :header => ['88D8A7','A788D8','A7D888','D888A7','D8A788','88A7D8'].collect{|c| "##{c}"},
        :data => ['CEE7FF','E7CEFF','E7FFCE','CEFFE7','FFCEE7','FFE7CE'].collect{|c| "##{c}"}
      }
    end

    def background_colors_12bit
      @@background_colors_12bit ||= {
        :header => background_colors_24bit[:header].collect{|c| convert_24to12(c)},
        :data => background_colors_24bit[:data].collect{|c| convert_24to12(c)}
      }
    end

    private
    
    def convert_24to12(color)
      rgb = color.gsub(/#/,'').upcase.gsub(/([0-9A-F]{2})/, '\1|').split('|')
      rgb.collect do |c|
        h = c.to_i(16)
        (h * 16 / 256).to_s(16)
      end.join
    end
  end
  
  def description
    self[:name].to_s.titleize
  end

  def refresh_interval
    ReportRequest.refresh_intervals[self[:refresh_interval_index].to_i]
  end

  def last_run_when
    self[:last_run_at].to_date.year == Date.null_date.year ? 'Never' : time_ago_in_words(self[:last_run_at])
  end

  def next_run_at
    if refresh_interval == :off
      next_run_at = Date.today
    elsif self[:last_run_at].to_date.year == Date.null_date.year
      next_run_at = Time.parse(Date.today.to_s)
    else
      monthly = self[:refresh_interval_index].to_i >= ReportRequest.refresh_intervals.index(:once_per_month)
      daily = !monthly && self[:refresh_interval_index].to_i >= ReportRequest.refresh_intervals.index(:every_12_hours)
      hourly = !daily && !monthly
      
      shift = case refresh_interval
      when :every_1_hour
        1
      when :every_3_hours
        3
      when :every_6_hours
        6
      when :every_12_hours
        12
      when :every_day
        1
      when :alternately_day
        2
      when :once_per_week
        7
      when :once_per_month
        1
      when :every_3_months
        3
      when :every_6_months
        6
      when :once_per_year
        12
      end
      
      last_run_at_date = self[:last_run_at].to_s.to_date
      if monthly || daily
        if monthly
          next_run_at = last_run_at_date >> shift
          next_run_at -= (next_run_at.day - 1) 
        else
          next_run_at = last_run_at_date + shift
        end
      else
        last_run_at_datehour = Time.parse(last_run_at_date.to_s) + (self[:last_run_at].hour * 60 * 60)
        next_run_at = last_run_at_datehour + (shift * 60 * 60)
      end

      next_run_at
    end
    
    next_run_at
  end

  def next_run_when
    if refresh_interval == :off
      'Not Updating'
    elsif next_run_at.year == Date.null_date.year || next_run_at >= Date.today
      'Updating'
    else
      time_ago_in_words(next_run_at)
    end
  end

  def col_report_request_cols(col_field_report, col_field_report_index = 0, report_request_col_id = nil)
    cfr = self.report.col_fields_reports[col_field_report_index]
    next_cfr = self.report.col_fields_reports[col_field_report_index+1]

    if cfr == col_field_report
      rrcs = [cfr.report_request_cols.select{|rrc| rrc.report_request_id == self[:id] && (report_request_col_id.nil? || rrc.report_request_col_id == report_request_col_id) }]
    elsif next_cfr != col_field_report
      rrcs = col_report_request_cols(col_field_report, col_field_report_index + 1)
    else
      rrcs = []
      cfr.report_request_cols.each do |rrc_p|
        rrcs += col_report_request_cols(col_field_report, col_field_report_index + 1, rrc_p.id)
      end
    end

    rrcs
  end

  def cell_report_request_cols
    report.cell_fields_reports.collect do |cf| 
      cf.report_request_cols.select{|rrc| rrc.report_request_id == self[:id] }
    end.flatten.sort{|a,b| a.id <=> b.id }
  end

  def load_field_filter_hash(field_filter=nil)
    if field_filter.nil?
      @field_filter_hash = {}
      field_filters.each do |f|
        @field_filter_hash[f.reference_screen_index] ||= {}
        @field_filter_hash[f.reference_screen_index][f.field_id] = f
      end
    else
      @field_filter_hash ||= {}
      @field_filter_hash[field_filter.reference_screen_index] ||= {}
      @field_filter_hash[field_filter.reference_screen_index][field_filter.field_id] = field_filter
    end
  end

  def field_filter(reference_screen_index, field_id)
    load_field_filter_hash if @field_filter_hash.nil? || @field_filter_hash[reference_screen_index].nil? || @field_filter_hash[reference_screen_index][field_id].nil?
    @field_filter_hash[reference_screen_index][field_id] if @field_filter_hash[reference_screen_index]
  end

  def visible_report_request_rows(options={})
    if !options[:sorting].nil? && options[:sorting] != :none
      rows = grand_total_row.sorted_visible_report_request_rows(options)
    else
      rows = self.report_request_rows
    end

    rows.select{|rrr| rrr.visible? }
  end

  def has_data?
    first_col = self.report.col_fields_reports.first

    @has_data ||= (!self.report_request_rows.find(:first).nil?) ||
      !first_col.nil? && !first_col.report_request_cols.find(:first).nil?
  end

  def grand_total_row
    rr_row = ReportRequestRow.new
    rr_row.id = 0
    rr_row.report_request = self
    rr_row.childs = self.parent_report_request_rows
    
    rr_row
  end
  
  def chart_data
    vm = VirtualMemory::load(:report_request, self[:id])
    
    vm[:chart_data]
  end

  def notification_period
    10.0 # second
  end

  def request
    VirtualMemory::store(:report_request, self[:id], nil)

    nil
  end
  
  def purge
    ReportRequestCell.purge(report_request_row_ids)
    ReportRequestRow.purge(self[:id])
    ReportRequestCol.purge(self[:id])

    self.report.reload_uncached_association unless self.report.nil?
    
    nil
  end
  
  def workflow_transition
    
    nil
  end
  
  def data_warehouse_etl
    vm = VirtualMemory::load(:report_request, self[:id])
    
    data_warehouse_etl_progress = vm.delete(:data_warehouse_etl_progress)

    if data_warehouse_etl_progress
      #~ Do Nothing
    else
      data_warehouse_etl_progress = {}
    end
    
    WorkFlow.execute(self, :progress => data_warehouse_etl_progress) if Rails.configuration.client_code =~ /susbkk/
    
    if data_warehouse_etl_progress.has_key?(:percentage) && data_warehouse_etl_progress[:percentage] < 1.0
      vm[:data_warehouse_etl_progress] = data_warehouse_etl_progress
    end
    
    VirtualMemory::store(:report_request, self[:id], vm)

    data_warehouse_etl_progress[:percentage]
  end

  # Fetch values for each column(Cross Tab)
  def save_columns
    vm = VirtualMemory::load(:report_request, self[:id])

    screen_ids = []
    rows = []
    save_label = []
    col_fields_reports = self.report.col_fields_reports
    col_fields_reports.each_with_index do |f, i|
      screen_ids << self.report.reference_screen_ids[f.reference_screen_index]

      ff = field_filter(f.reference_screen_index, f.field_id)
      if f.field_id < 0
        selected_ids = ff.nil? ? [] : ff.selected_ids
        save_label[i] = :row_src
        rows[i] = f.report.reference_screens[f.reference_screen_index].rows.collect{|r| r.id if selected_ids.empty? || selected_ids.include?(r.id)}.compact
      else
        case f.field.custom_field
        when CustomFields::Reference then
          selected_ids = ff.nil? ? [] : ff.selected_ids
          save_label[i] = :row_src
          rows[i] = f.field.custom_field.screen.rows.collect{|r| r.id if selected_ids.empty? || selected_ids.include?(r.id)}.compact
        when CustomFields::ComboBox, CustomFields::CheckBox, CustomFields::RadioButton, CustomFields::ListBox then
          selected_ids = ff.nil? ? [] : ff.selected_ids
          save_label[i] = :label_src
          rows[i] = f.field.custom_field.label_ids.collect{|l_id| l_id if selected_ids.empty? || selected_ids.include?(l_id)}.compact
        when CustomFields::LoginField  then
          save_label[i] = :login_src
          selected_ids = ff.nil? ? [] : ff.selected_ids
          users = User.find(:all)
          rows[i] = users.collect{|u| u.id if selected_ids.empty? || selected_ids.include?(u.id)}.compact
        when CustomFields::DateTimeField then
          save_label[i] = :date_src

          # Set default col format to long month
          f.field_format ||= {}
          f.field_format[:format] ||= :long_month
          
          rows[i] = CustomFields::DateTimeField.get_month_by_types(f.field_format[:format])
        when CustomFields::Calendar then
          save_label[i] = :date_src
          #~ ToDo: Use field_format to set displaying format (not field_report_filter's format
          rows[i] = CustomFields::DateTimeField.get_month_by_types(:long_month)
        when CustomFields::IssueTracking then
          # need to implement more
        end
      end
    end

    screens = screen_ids.collect{|s_id| Screen.find(s_id) }

    # Genarate all possible combinations
    combination_cols = (rows.length == 0) ? [] : rows[0]
    index = 1
    while (rows.length > index)
      combination_cols = combination_cols.cartprod(rows[index])

      screen = screens[index]
      a_field = screen.fields.select{|f| col_fields_reports[index].field_id == f.id }.first
      (0..index-1).each do |i|
        if screen_ids[i] == screen_ids[index]
          b_field = screen.fields.select{|f| col_fields_reports[i].field_id == f.id }.first
          
          combination_cols.delete_if do |row_ids|
            a_row_id = row_ids[index]
            b_row_id = row_ids[i]

            !screen.rows.any? do |r|
              actual_row_a = Field.row_by_field(a_field, r)
              actual_row_b = Field.row_by_field(b_field, r)
              r_a_row_id = CustomFields::Reference.cell_ref_row_id(actual_row_a.cell(a_field.custom_field_id)) unless actual_row_a.nil?
              r_b_row_id = CustomFields::Reference.cell_ref_row_id(actual_row_b.cell(b_field.custom_field_id)) unless actual_row_b.nil?

              r_a_row_id.to_i == a_row_id.to_i && r_b_row_id.to_i == b_row_id.to_i
            end
          end if b_field.is_a?(Fields::Data) && b_field.custom_field.is_a?(CustomFields::Reference)
        end
      end if a_field.is_a?(Fields::Data) && a_field.custom_field.is_a?(CustomFields::Reference)
      
      criterias = self.report.criterias.select do |c|
        a_screen_index = screen_ids.index(self.report.reference_screen_ids[c[:a_screen_index]])
        b_screen_index = screen_ids.index(self.report.reference_screen_ids[c[:b_screen_index]])

        [a_screen_index, b_screen_index].max == index unless a_screen_index.nil? || b_screen_index.nil?
      end

      criteria_screen_indexes = criterias.collect do |c|
        a_screen_index = screen_ids.index(self.report.reference_screen_ids[c[:a_screen_index]])
        b_screen_index = screen_ids.index(self.report.reference_screen_ids[c[:b_screen_index]])

        [a_screen_index, b_screen_index]
      end.flatten.uniq.sort

      ht_screen_rows = {}
      criteria_screen_indexes.each do |s_idx|
        ht_screen_rows[s_idx] = {}

        col_rows = Row.find(:all,
          :include => [:cells],
          :conditions => {
            :rows => { :id => rows[s_idx], :screen_id => screen_ids[s_idx] }
          }
        )

        col_rows.each{|r| ht_screen_rows[s_idx][r.id] = r }
      end

      criterias.each do |c|
        a_i = screen_ids.index(self.report.reference_screen_ids[c[:a_screen_index]])
        b_i = screen_ids.index(self.report.reference_screen_ids[c[:b_screen_index]])

        next if a_i.nil? || b_i.nil?

        oper = c[:operation]

        combination_cols.delete_if do |d|
          a_value, b_value = data_value(d, a_i, b_i, c, screens, ht_screen_rows, index, screen_ids)

          next if a_value.nil? || b_value.nil?

          comparison = case oper
          when '=='
            a_value == b_value
          when '!='
            a_value != b_value
          when '<'
            a_value < b_value
          when '<='
            a_value <= b_value
          when '>'
            a_value > b_value
          when '>='
            a_value >= b_value
          end

          !comparison
        end
      end

      index += 1
    end

    # Generate sub fields for each CellFieldsReports
    combination_cols = combination_cols.cartprod(self.report.cell_fields_reports.collect{|fr| fr.id})
    ht_cell_fields_reports_types = {}
    self.report.cell_fields_reports.each{|fr| ht_cell_fields_reports_types[fr.id] = fr.field_type}

    # Traversal in to the tree structure and create each node (columns)
    previous = []
    parent_cols = {}
    ht_rr_cols = {}
    report_request_columns = []
    combination_cols.each_with_index do |ar_row_ids, i|
      save = false || (i == 0)
      rr_col = nil
      ar_row_ids.each_with_index do |r_id, j|
        save = (save || previous[j] != ar_row_ids[j])
        field_key = j == (ar_row_ids.length - 1)
        key = case
        when !field_key
          save_label[j]
        when ht_cell_fields_reports_types[r_id] == :formula
          :formula_src
        else
          :field_src
        end
        parent_col = (j == 0) ? nil : parent_cols["#{ar_row_ids[j-1]}_#{col_fields_reports[j-1].id}"][save_label[j-1]]

        if save
          fields_report_id = field_key ? r_id : col_fields_reports[j].id
          rr_col = save_column(r_id, key ,
            parent_col.nil? ? nil : parent_col.id,
            fields_report_id)
          parent_cols.merge!({"#{r_id}_#{fields_report_id}" => {key => rr_col}})
        end
      end

      # Hold on to each leaf, will use to create cells
      ht_rr_cols[ar_row_ids.join('-')] = rr_col.id
      report_request_columns << rr_col

      previous = ar_row_ids
    end

    self.report.reload_uncached_association

    vm[:ht_rr_cols] = ht_rr_cols

    VirtualMemory::store(:report_request, self[:id], vm)

    nil
  end

  def filter_row_values
    vm = VirtualMemory::load(:report_request, self[:id])
    
    filter_row_values_progress = vm.delete(:filter_row_values_progress)
    
    # prepare hash data
    if filter_row_values_progress
      ht_screen_row_ids = vm.delete(:ht_screen_row_ids)
      screen_ids = vm.delete(:screen_ids)
    else
      ht_screen_row_ids = {}
      screen_ids = self.report.reference_screen_ids

      filter_row_values_progress = { :screen_index => 0 }
    end

    return -1 if self.report.row_fields_reports.empty?
    
    screen_index = filter_row_values_progress[:screen_index]

    screen_id = screen_ids[screen_index]
    screen = Screen.find(screen_id)
    
    ht_screen_row_ids[screen_index] = filter_screen_rows_by_field_filter(screen, screen_index)

    return -1 if ht_screen_row_ids[screen_index].empty?

    filter_row_values_progress[:screen_index] = screen_index + 1

    filter_row_values_progress[:percentage] = filter_row_values_progress[:screen_index].to_f / screen_ids.length

    if filter_row_values_progress[:percentage] < 1.0
      vm[:filter_row_values_progress] = filter_row_values_progress
    end
    
    vm[:ht_screen_row_ids] = ht_screen_row_ids
    vm[:screen_ids] = screen_ids
    
    VirtualMemory::store(:report_request, self[:id], vm)

    filter_row_values_progress[:percentage]
  end

  def remove_unreferred_rows
    vm = VirtualMemory::load(:report_request, self[:id])
    
    remove_unreferred_rows_progress = vm.delete(:remove_unreferred_rows_progress)
    ht_screen_row_ids = vm.delete(:ht_screen_row_ids)
    
    screen_ids = vm[:screen_ids]
    
    # prepare hash data
    if remove_unreferred_rows_progress
      ht_reffered_row_ids = vm.delete(:ht_reffered_row_ids)
    else
      ht_reffered_row_ids = []

      remove_unreferred_rows_progress = { :screen_index => 0 }
    end

    screen_index = remove_unreferred_rows_progress[:screen_index]
    
    screens = screen_ids.collect{|s_id| Screen.find(s_id) }

    ht_reffered_row_ids[screen_index] ||= []
    ht_reffered_row_ids[screen_index] += reffered_row_ids(screen_index, screens, ht_screen_row_ids)
    
    if screen_index == screen_ids.length - 1
      ht_screen_row_ids.each_key do |s_idx|
        ht_screen_row_ids[s_idx] &= ht_reffered_row_ids[s_idx] unless ht_reffered_row_ids[s_idx].empty? || self.report.is_outer_join?(s_idx)
      end
    end
    
    remove_unreferred_rows_progress[:screen_index] = screen_index + 1

    remove_unreferred_rows_progress[:percentage] = remove_unreferred_rows_progress[:screen_index].to_f / screen_ids.length

    if remove_unreferred_rows_progress[:percentage] < 1.0
      vm[:ht_reffered_row_ids] = ht_reffered_row_ids
      
      vm[:remove_unreferred_rows_progress] = remove_unreferred_rows_progress
    end
    
    vm[:ht_screen_row_ids] = ht_screen_row_ids
    
    VirtualMemory::store(:report_request, self[:id], vm)

    remove_unreferred_rows_progress[:percentage]
  end

  def check_row_relations
    vm = VirtualMemory::load(:report_request, self[:id])
    
    check_row_relations_progress = vm.delete(:check_row_relations_progress)
    ht_screen_row_ids = vm.delete(:ht_screen_row_ids)
    screen_ids = vm.delete(:screen_ids)
    
    # prepare hash data
    if check_row_relations_progress
      all_rows = vm.delete(:all_rows)
    else
      all_rows = nil
    
      check_row_relations_progress = { :screen_index => 0 }
    end

    return -1 if self.report.row_fields_reports.empty?

    screen_index = check_row_relations_progress[:screen_index]
    
    screens = screen_ids[0..screen_index].collect{|s_id| Screen.find(s_id) }

    if screen_index == 0
      all_rows = ht_screen_row_ids[screen_index].collect{|r_id| [r_id] }
    elsif !ht_screen_row_ids[screen_index].nil? && ht_screen_row_ids[screen_index].empty?
      all_rows = []
    elsif !ht_screen_row_ids[screen_index].nil?
      all_rows = all_rows.cartprod(ht_screen_row_ids[screen_index])
    end

    return -1 if all_rows.empty?

    criterias = self.report.criterias.select {|c| [c[:a_screen_index], c[:b_screen_index]].max == screen_index }
    criteria_screen_indexes = criterias.collect{|c| [c[:a_screen_index], c[:b_screen_index]]}.flatten.uniq.sort
    
    ht_screen_rows = {}
    criteria_screen_indexes.each do |s_idx|
      ht_screen_rows[s_idx] = {}

      rows = Row.find(:all,
        :include => [:cells],
        :conditions => {
          :rows => { :id => ht_screen_row_ids[s_idx], :screen_id => screen_ids[s_idx] }
        }
      )
      
      rows.each{|r| ht_screen_rows[s_idx][r.id] = r }
    end
    
    criterias.each do |c|
      a_i = c[:a_screen_index]
      b_i = c[:b_screen_index]
      oper = c[:operation]
      
      all_rows.delete_if do |d|
        a_value, b_value = data_value(d, a_i, b_i, c, screens, ht_screen_rows, screen_index, screen_ids)

        comparison = case oper
        when '=='
          a_value == b_value
        when '!='
          a_value != b_value
        when '<'
          a_value < b_value
        when '<='
          a_value <= b_value
        when '>'
          a_value > b_value
        when '>='
          a_value >= b_value
        end unless a_value.nil? || b_value.nil?
        
        !comparison
      end
    end

    criterias.each do |c|
      a_i = c[:a_screen_index]
      b_i = c[:b_screen_index]
      
      (0..screen_index).each do |i|
        next unless self.report.is_outer_join?(i)
        
        screen_row_ids = all_rows.collect{|rows| rows[i]}.compact.uniq
        
        return_row_ids = ht_screen_row_ids[i] - screen_row_ids
        return_row_ids.each do |r_id|
          return_rows = Array.new(ht_screen_row_ids.length)
          return_rows[i] = r_id
          
          a_value, b_value = data_value(return_rows, a_i, b_i, c, screens, ht_screen_rows, screen_index, screen_ids)
          
          return_rows[a_i] ||= b_value if return_rows[b_i] != b_value && self.report.is_outer_join?(b_i)
          return_rows[b_i] ||= a_value if return_rows[a_i] != a_value && self.report.is_outer_join?(a_i)
          
          all_rows << return_rows unless all_rows.include?(return_rows)
        end unless return_row_ids.empty?
      end 
    end

    # Purge unreferred rows
    criteria_screen_indexes.each {|s_idx| ht_screen_row_ids[s_idx] = [] }
    all_rows.each do |row_ids|
      row_ids.each_with_index do |r_id, s_idx|
        ht_screen_row_ids[s_idx] << r_id unless r_id.nil?
      end
    end unless criteria_screen_indexes.empty?
    criteria_screen_indexes.each {|s_idx| ht_screen_row_ids[s_idx].uniq! }

    # start_time = Time.now

#    check_point_time = Time.now
#    break if (check_point_time - start_time) > notification_period

    check_row_relations_progress[:screen_index] = screen_index + 1

    check_row_relations_progress[:percentage] = check_row_relations_progress[:screen_index].to_f / (screen_ids.length + 1)

    if check_row_relations_progress[:percentage] < 1.0
      vm[:check_row_relations_progress] = check_row_relations_progress
    end
    
    vm[:all_rows] = all_rows
    vm[:ht_screen_row_ids] = ht_screen_row_ids
    vm[:screen_ids] = screen_ids
    
    VirtualMemory::store(:report_request, self[:id], vm)

    check_row_relations_progress[:percentage]
  end

  def sort_row_cols
    vm = VirtualMemory::load(:report_request, self[:id])
    
    all_rows = vm[:all_rows]

    # re-order column
    rfr_screen_indexes = self.report.row_field_report_screen_indexes
    sorted_datas = all_rows.collect do |d|
      rfr_screen_indexes.collect{|s_idx| (d[s_idx] == 0 || d[s_idx].nil?) ? -s_idx : d[s_idx] }
    end

    sorted_datas = sorted_datas.select{|r| !r.empty?} # Remove empty rows
    sorted_datas.sort!  # Sort the result for grouping
    sorted_datas.uniq!  # Unique the result for grouping

    vm[:sorted_datas] = sorted_datas
    vm[:rfr_screen_indexes] = rfr_screen_indexes

    VirtualMemory::store(:report_request, self[:id], vm)

    nil
  end
  
  def save_rows
    vm = VirtualMemory::load(:report_request, self[:id])

    save_rows_progress = vm.delete(:save_rows_progress)
    sorted_datas = vm.delete(:sorted_datas)

    rfr_screen_indexes = vm[:rfr_screen_indexes]
    
    if save_rows_progress
      ht_rr_rows = vm.delete(:ht_rr_rows)
      previous = vm.delete(:previous)
      parent_row_ids = vm.delete(:parent_row_ids)
    else
      ht_rr_rows = {}
      previous = []
      parent_row_ids = {}
      
      save_rows_progress = { :row_index => 0 }
    end

    start_time = Time.now
    
    #2. save row
    rr_row = nil
    ActiveRecord::Base.transaction do
      sub_sorted_datas = sorted_datas[save_rows_progress[:row_index]..sorted_datas.length]
      
      sub_sorted_datas.each do |ar_row_ids|
        i = save_rows_progress[:row_index]
        
        r_value = []
        save = (i == 0)
        
        check_point_time = Time.now
        
        break if i != 0 && previous[0] != ar_row_ids[0] && (check_point_time - start_time) > notification_period
        
        save_rows_progress[:row_index] = i + 1
        
        ar_row_ids.each_with_index do |r_id, j|
          r_value << r_id
          save = (save || previous[j] != ar_row_ids[j])
          
          if save
            parent_row_id = (j == 0) ? nil : parent_row_ids["#{ar_row_ids[j-1]}"]
            rr_row = save_row(r_id, parent_row_id, rfr_screen_indexes[j])
            parent_row_ids.merge!({"#{r_id}" => rr_row.id})
          end
        end
        
        ht_rr_rows[r_value.join('-')] = rr_row.id
        previous = ar_row_ids
      end
    end
    
    self.report.reload_uncached_association

    save_rows_progress[:percentage] = save_rows_progress[:row_index].to_f / sorted_datas.length

    if save_rows_progress[:percentage] < 1.0
      vm[:sorted_datas] = sorted_datas
      vm[:previous] = previous
      vm[:parent_row_ids] = parent_row_ids
      vm[:save_rows_progress] = save_rows_progress
    end
    
    vm[:ht_rr_rows] = ht_rr_rows

    VirtualMemory::store(:report_request, self[:id], vm)

    save_rows_progress[:percentage]
  end

  def fetch_cell_values()
    vm = VirtualMemory::load(:report_request, self[:id])
    
    all_rows = vm.delete(:all_rows)
    ht_screen_row_ids = vm.delete(:ht_screen_row_ids)
    rfr_screen_indexes = vm.delete(:rfr_screen_indexes)

    col_fields_reports = self.report.col_fields_reports
    cell_fields_reports = self.report.cell_fields_reports

    ht_screen_rows = reload_ht_screen_rows(ht_screen_row_ids) unless col_fields_reports.empty? && cell_fields_reports.empty?

    fetch_cell_values_progress = vm.delete(:fetch_cell_values_progress)
    
    if fetch_cell_values_progress
      all_rows_cells = vm.delete(:all_rows_cells)
      include_calendar_values = vm.delete(:include_calendar_values)
      ht_cell_calendar_value_row_ids = vm.delete(:ht_cell_calendar_value_row_ids)
    else
      all_rows_cells = {}

      fields = []
      self.report.reference_screens.each_with_index do |rs, s_idx|
        rs.fields.each do |f|
          f.custom_field.detail_screen.fields.each do |df|
            self.report.fields_reports.each do |fr|
              field = [f.custom_field_id, s_idx] if (f.id == fr.field_id || df.id == fr.field_id) && s_idx == fr.reference_screen_index
              fields << field unless field.nil? || fields.include?(field)
            end
          end if f.custom_field.is_a?(CustomFields::Calendar)
        end
      end

      include_calendar_values = false
      ht_cell_calendar_value_row_ids = {}
      cv_screen_row_ids = []
      new_all_rows = []

      all_rows.each do |r_ids|
        cv_row_ids = fields.collect do |custom_field_id, reference_screen_index|
          row_col_id = r_ids[reference_screen_index]
          row_col = ht_screen_rows[reference_screen_index][row_col_id]
          cell = row_col.cell(custom_field_id) unless row_col.nil?

          if cell
            filter_month = nil

           #~ Search for the Month filter
            self.report.field_report_filters.each do |frf|
              next if frf.reference_screen_index != reference_screen_index
              
              ff = self.field_filter(frf.reference_screen_index, frf.field_id)
              unless ff.nil? || ff.field_id < 0
                case ff.field.custom_field
                when CustomFields::Calendar
                  if frf.filter == :long_month
                    filter_month = ff.accounting_month
                  end
                end
              end
            end

            calendar_values = filter_month ? [cell.calendar_values[filter_month-1]] : cell.calendar_values

            calendar_values.collect do |cv|
              #~ ToDo: Replace row fetching with cache (in memory)
              detail_row = DetailRow.find(cv.row_id)

              cv.row_id unless cell_fields_reports.all?{|cfr|
                if cfr.field.is_a?(Fields::Data)
                  actual_row = Field.row_by_field(cfr.field, detail_row)
                  cell = actual_row.cell(cfr.field.custom_field_id) unless actual_row.nil?
                  cell.nil?
                end
              }
            end.compact
          end
        end.flatten.compact

        next if cv_row_ids.empty?

        cv_screen_row_ids += cv_row_ids
        new_all_rows += [r_ids].cartprod(cv_row_ids)
      end

      unless new_all_rows.empty?
        all_rows = new_all_rows

        cv_screen_index = self.report.reference_screen_ids.length

        ht_cv_screen_row_ids = { cv_screen_index => cv_screen_row_ids }
        cv_screen_rows = reload_ht_screen_rows(ht_cv_screen_row_ids)

        ht_screen_row_ids[cv_screen_index] = cv_screen_row_ids
        ht_screen_rows[cv_screen_index] = cv_screen_rows.delete(cv_screen_index)

        include_calendar_values = true
      end

      fetch_cell_values_progress = { :result_index => 0 }
    end
    
    start_time = Time.now

    sub_rows = all_rows[fetch_cell_values_progress[:result_index]..all_rows.length]

    sub_rows.each do |r_ids|
      result_index = fetch_cell_values_progress[:result_index]

      #1. col => cell value + rr_field_id
      #2. row => row_rr_row_id
      ar_cols = []
      col_fields_reports.each_with_index do |col_fr,i|
        row_col_id = r_ids[col_fr.reference_screen_index]
        row_col = ht_screen_rows[col_fr.reference_screen_index][row_col_id]
        if col_fr.field_id < 0 then
          cell_col_value ||= []
          cell_col_value = [row_col.id] unless row_col.nil?
        else
          unless row_col.nil?
            actual_row = Field.row_by_field(col_fr.field, row_col)
            cell = actual_row.cell(col_fr.field.custom_field_id) unless actual_row.nil?
          end
          if cell
            case col_fr.field.custom_field
            when CustomFields::Reference then # row_id
              cell_col_value = [CustomFields::Reference.cell_ref_row_id(cell.value)]
            when CustomFields::ComboBox then # label_id
              cell_col_value = [CustomFields::ComboBox.cell_label_id(cell.value)]
            when CustomFields::RadioButton then # label_id
              cell_col_value = [CustomFields::RadioButton.cell_label_id(cell.value)]
            when CustomFields::LoginField  then
              cell_col_value = [cell.value]
            when CustomFields::DateTimeField then # DateTime
              dt_value = cell.value
              cell_col_value = CustomFields::DateTimeField.get_months_path_by_date(dt_value)  # [1, 13, 17, 19]
            when CustomFields::Calendar then # Calendar
              cv_screen_index = r_ids.length-1
              cv_row_id = r_ids[cv_screen_index]
              ht_cell_calendar_value_row_ids[row_col_id] ||= cell.calendar_values.collect{|cv| cv.row_id }
              cell_calendar_value_row_ids = ht_cell_calendar_value_row_ids[row_col_id]
              cv_index = cell_calendar_value_row_ids.index(cv_row_id)
              cv = cell.calendar_values[cv_index]
              cell_col_value = CustomFields::DateTimeField.get_months_path_by_date(cv.date_time) # [1, 13, 17, 19]
            when CustomFields::ListBox then
              # need to implement more
            end
          else
            cell_col_value = []
          end
        end
        ar_cols = ar_cols.empty? ? [cell_col_value].flatten : ar_cols.cartprod(cell_col_value)
      end
      
      row_key_ids = rfr_screen_indexes.collect{|s_idx| (r_ids[s_idx] == 0 || r_ids[s_idx].nil?) ? -s_idx : r_ids[s_idx] }
      
      row_key = row_key_ids.join('-')
      all_rows_cells[row_key] ||= {}

      ar_cols.collect! do |col_key_values|
        col_key_values = [col_key_values] unless col_key_values.is_a?(Array)
        col_key_values << nil
      end
      
      cell_fields_reports.each_with_index do |cell_fr,i|
        ar_cols.each do |col_key_values|
          if include_calendar_values
            r_id_screen_index, row_screen_index = r_ids.length-1, self.report.reference_screen_ids.length
          else
            r_id_screen_index, row_screen_index = cell_fr.reference_screen_index, cell_fr.reference_screen_index
          end

          row_cell_id = r_ids[r_id_screen_index]
          row_cell = ht_screen_rows[row_screen_index][row_cell_id]
          
          col_key_values[col_key_values.length-1] = cell_fr.id.to_s
          col_key = col_key_values.join('-')
          
          all_rows_cells[row_key][col_key] ||= {:summarize => cell_fr.summarize, :values => []}

          case cell_fr.field
          when NilClass then
              cell_value = row_cell.description
              new_cell_value = cell_value unless cell_value.nil?
          when Fields::Data then
            case cell_fr.field.custom_field
            when CustomFields::Reference,
                 CustomFields::RadioButton,
                 CustomFields::ComboBox then
              actual_row = Field.row_by_field(cell_fr.field, row_cell)
              cell_value = actual_row.cell(cell_fr.field.custom_field_id) unless actual_row.nil?
              new_cell_value = cell_value.to_text unless cell_value.nil?
            when CustomFields::LoginField  then
              new_cell_value = row_cell.description
            when CustomFields::DateTimeField then
              actual_row = Field.row_by_field(cell_fr.field, row_cell)
              cell_value = actual_row.cell(cell_fr.field.custom_field_id) unless actual_row.nil?
              new_cell_value = cell_value.to_text unless cell_value.nil?
            when CustomFields::ListBox then
              # need to implement more
            else
              actual_row = Field.row_by_field(cell_fr.field, row_cell)
              cell_value = actual_row.cell(cell_fr.field.custom_field_id) unless actual_row.nil?
              new_cell_value = cell_value.absolute_value unless cell_value.nil?
            end
          else
            new_cell_value = cell_fr.field.evaluate_value(row_cell)
          end

          next if new_cell_value.nil?

          all_rows_cells[row_key][col_key][:values] << new_cell_value
        end if cell_fr.field_type != :formula
      end

      fetch_cell_values_progress[:result_index] = result_index + 1
      
      check_point_time = Time.now

      break if (check_point_time - start_time) > notification_period
    end

    fetch_cell_values_progress[:percentage] = fetch_cell_values_progress[:result_index].to_f / all_rows.length
    
    if fetch_cell_values_progress[:percentage] < 1.0
      vm[:all_rows] = all_rows
      vm[:ht_screen_row_ids] = ht_screen_row_ids
      vm[:rfr_screen_indexes] = rfr_screen_indexes
      vm[:fetch_cell_values_progress] = fetch_cell_values_progress
      vm[:include_calendar_values] = include_calendar_values
      vm[:ht_cell_calendar_value_row_ids] = ht_cell_calendar_value_row_ids
    end
    
    vm[:all_rows_cells] = all_rows_cells
    
    VirtualMemory::store(:report_request, self[:id], vm)

    fetch_cell_values_progress[:percentage]
  end

  def save_cells()
    vm = VirtualMemory::load(:report_request, self[:id])

    all_rows_cells = vm.delete(:all_rows_cells)
    ht_rr_rows = vm.delete(:ht_rr_rows)
    ht_rr_cols = vm.delete(:ht_rr_cols)

    save_cells_progress = vm.delete(:save_cells_progress)

    unless save_cells_progress
      save_cells_progress = {:key_index => 0}
    end

    #3. save cell
    all_rows_cells_keys = all_rows_cells.keys

    start_time = Time.now

    ActiveRecord::Base.transaction do
      sub_rows_cells_keys = all_rows_cells_keys[save_cells_progress[:key_index]..all_rows_cells_keys.length]

      sub_rows_cells_keys.each do |r_k|
        i = save_cells_progress[:key_index]

        check_point_time = Time.now

        break if (check_point_time - start_time) > notification_period

        save_cells_progress[:key_index] = i + 1

        r_v = all_rows_cells[r_k]
        row_rr_row_id = ht_rr_rows[r_k]
        r_v.each do |c_k, c_v|
          col_rr_row_id = ht_rr_cols[c_k]
          save_cell(row_rr_row_id, col_rr_row_id, c_v )
        end
      end
    end

    self.report.reload_uncached_association

    save_cells_progress[:percentage] = save_cells_progress[:key_index].to_f / all_rows_cells_keys.length

    if save_cells_progress[:percentage] < 1.0
      vm[:all_rows_cells] = all_rows_cells
      vm[:ht_rr_rows] = ht_rr_rows
      vm[:ht_rr_cols] = ht_rr_cols

      vm[:save_cells_progress] = save_cells_progress
    end

    VirtualMemory::store(:report_request, self[:id], vm)

    save_cells_progress[:percentage]
  end

  def remove_unreferred_cols
    vm = VirtualMemory::load(:report_request, self[:id])
    
    VirtualMemory::store(:report_request, self[:id], vm)

    nil
  end
  
  def cache_chart_data()
    vm = VirtualMemory::load(:report_request, self[:id])

    vm[:chart_data] = fetch_chart_data

    VirtualMemory::store(:report_request, self[:id], vm)

    nil
  end

  def save_to(output_format)
    result = {
      :local_filename => local_filename,
      :filename => "#{self.name.gsub(/[ \\\/:*?"<>|]/,'_').gsub(/[_]+/,'_')}.#{output_format.to_s}"
    }

    options = {}

    case output_format
    when :csv
      result[:type] = 'text/csv'
    when :xls
      options[:palette] = ReportRequest.background_colors_24bit[:header] +
        ReportRequest.background_colors_24bit[:data]
    end

    save_to_method = "save_to_#{output_format}"
    if self.respond_to?(save_to_method)
      self.send(save_to_method, result[:local_filename], options)
    else
      raise "Unimplemented format '#{output_format}'"
    end

    result
  end

  def values
    @report_request_row_values ||= (visible_report_request_rows(self.report.sorting_options) + [grand_total_row]).collect{|rrr| rrr.values }
  end
  
  private
  
  def local_filename
    File.join(RAILS_ROOT, 'tmp', 'cache', 'rpt', "#{self[:id]}.tmp")
  end
  
  # Headers
  def csv_header_data
    []
  end

  # Field descriptions
  def csv_field_descr
    @csv_field_descrs = {}

    if @csv_field_descrs.empty?
      columns = row_columns.flatten + cell_columns
      columns.each{|c| @csv_field_descrs[c[:id]] = c[:descr] }
    end

    @csv_field_descrs
  end

  # The displaying order when genarating the CSV
  def csv_field_sequence
    @csv_field_sequence ||= row_columns.flatten.collect{|c| c[:id] } + cell_columns.collect{|c| c[:id] }
  end

  # The data that will be written to the csv_field_sequence
  def csv_data_collection()
    grand_total_row.leaf_report_request_rows.collect{|rrr| rrr.values(:all_fields => true).collect{|c_v| c_v[:value] } }
  end

  def excel_info
    info = []
    info << [{:type => :text, :descr => "#{Label.descr_by_name('G_NAME')}: "}, {:type => :text, :descr => self.name}]
    info << [{:type => :text, :descr => 'Report: '}, {:type => :text, :descr => self.report.name}]
    info << [{:type => :text, :descr => 'Interval: '}, {:type => :text, :descr => self.refresh_interval.to_s.titleize}]
    info << [{:type => :text, :descr => 'Last Run: '}, {:type => :text, :descr => self.last_run_when =~ /never/i ? ' ' : self.last_run_when}]
    info << [{:type => :text, :descr => 'Remark: '}, {:type => :text, :descr => self.remark}]
  
    info_cells = []
    info.each do |inf|
      info_cells << inf.collect{|i| excel_wrap_data(i[:type], i[:descr], nil)}
    end

    info_cells
  end
  
  def excel_filter

    filters = []

    screens = self.report.reference_screens
    screens.each_with_index do |s, s_idx|
      printed_header = false
      self.report.field_report_filters.each do |frf|
        next if frf.reference_screen_index != s_idx

        if !printed_header
          filters << [{:type => :header, :descr => s.name, :col_span => 2}]
          printed_header = true
        end
        
        filter_row_ids = []
        ff = self.field_filter(frf.reference_screen_index, frf.field_id)

        if ff.field_id < 0
          filter_row_ids = ff.selected_ids
          filter_row_ids.each do |f|
            filters << [{:type => :text, :descr => '', :col_span => 1}, {:type => :text, :descr => Row.find(f).description, :col_span => 1}] if f.to_i > 0
          end
        else
          case ff.field.custom_field
          when CustomFields::DateTimeField then
            if frf.filter == :long_date
              filters << [{:type => :text, :descr => ff.field.descr, :col_span => 1}, {:type => :text, :descr => ff.value, :col_span => 1}]
            else
              # ToDo: Move this algorithm, on how to get the date range from the Month, Quarter, Half, Year
              # to the CustomFields::DateTimeField
              null_date = Date.null_date

              # Get dt_from
              value = case frf.filter
              when :long_month then
                "#{ff.accounting_year}-#{ff.accounting_month}"
              when :quarter_year then
                month_shift = 3
                dt_from = Date.new(ff.accounting_year, null_date.month, null_date.day)
                quarter_shift = (ff.accounting_month - 13) * month_shift
                dt_from = (dt_from >> quarter_shift)
                dt_to = (dt_from >> month_shift) - 1
                "#{dt_from} - #{dt_to}"
              when :half_year then
                month_shift = 6
                dt_from = Date.new(ff.accounting_year, null_date.month, null_date.day)
                quarter_shift = (ff.accounting_month - 17) * month_shift
                dt_from = (dt_from >> quarter_shift)
                dt_to = (dt_from >> month_shift) - 1
                "#{dt_from} - #{dt_to}"
              when :year then
                "#{ff.accounting_year}"
              end

              filters << [{:type => :text, :descr => ff.field.descr, :col_span => 1}, {:type => :text, :descr => value, :col_span => 1}]
            end
          when CustomFields::Calendar
            filters << [{:type => :text, :descr => ff.field.descr, :col_span => 1}, {:type => :text, :descr => ff.accounting_year, :col_span => 1}]
          else
            ff.value[:selected_ids].each do |f|
              header_descr = ''
              row_span = 1
              if f == ff.value[:selected_ids].first
                header_descr = ff.field.descr
                row_span = ff.value[:selected_ids].size - 1
              end
              filters << [{:type => :text, :descr => header_descr, :col_span => 1, :row_span => row_span}, {:type => :text, :descr => Row.find(f).description, :col_span => 1}] if f.to_i > 0
            end if !ff.value.nil? && !ff.value[:selected_ids].nil?
          end
        end if !ff.nil?
      end
    end

    filter_cells = []
    filters.each do |fc|
      filter_cells << fc.collect{|f| excel_wrap_data(f[:type], f[:descr], nil, f[:col_span], f[:row_span] || 1)}
    end

    filter_cells
  end
  
  def excel_chart
    chart = []
    #~ Chart
    if self.report.display_chart?
      #~ ToDo: Calculate the image col and row span
      chart << [excel_wrap_data( :image, DualChart.path(self[:id]))] unless self.report.cell_fields_reports.select{|cfr| cfr.chart_axis != :none }.empty?
      #~ ToDo: Calculate the number of rows to skip
      chart += (0..25).to_a.collect{|i| []}

      #~ ToDo: Change the image to a ExcelChart object
    end

    chart
  end

  def excel_header_data
    headers = []
    report_header_row_size = self.report.col_fields_reports.size + 1
    cells = self.report.cell_fields_reports
    unless self.report.col_fields_reports.empty?
      header_cells = cell_columns(nil, self.report.cell_location).collect do |cc|
        rr_col = ReportRequestCol.find(:first, :conditions => ['id = ?', cc[:id].abs])
        if !rr_col.nil?
          cells_col = rr_col.each_col_array.flatten
          cells_col_descr = cells_col.collect do |cell_col|
            descr =  if self.report.cell_location == :col && cells_col.size == report_header_row_size && cc[:id] < 0 && cell_col == cells_col.last
              '%'
            elsif self.report.cell_location == :row && cells_col.size == report_header_row_size && cell_col == cells_col.last
              cc[:descr]
            else
              cell_col.descr
            end

            { :descr => descr }
          end

          # fill description in empty cell
          level = cells_col_descr.size
          while cells_col_descr.size < report_header_row_size do
            descr = cells_col_descr.size != report_header_row_size - 1 ? "Sub Total - #{level}" :
                      cc[:id] < 0 ? '%' : cells.collect{ |c| c.descr if !cc[:descr].scan(c.descr).empty? }.compact.first
            cells_col_descr <<  { :descr => descr }
          end
          cells_col_descr
        else
          col_fields = self.report.col_fields_reports
          col_fields.collect { |c| { :descr => 'Grand Total' } } << { :descr => cc[:descr].gsub(/Grand Total - /, '') }
        end
      end.transpose
      header_cells = set_merge(header_cells, :col, -1)
      header_cells = set_merge(header_cells, :row, -1)
    end

    header_cells ||= [[]]
    header_cells.each_with_index do |c, i|

      row_column_size = row_columns.size
      row_column_size += 1 if self.report.cell_location == :row

      header_row_cells = (header_cells.last == c ? (self.report.cell_location == :row ? row_columns + [:descr => '']: row_columns) :
          [:descr => self.report.col_fields_reports[i].descr] << (1..row_column_size-1).collect{|d| {:descr => self.report.col_fields_reports[i].descr} })

      header_row_cells = set_merge([header_row_cells.flatten], :col)

      columns = header_row_cells.first + c

      headers << columns.collect{|cc| excel_wrap_data(:header, cc[:descr], nil, cc[:col_span], cc[:row_span])}
    end

    headers
  end

  def excel_data
    datas = []
    rows_values = values
    if self.report.cell_location == :row
      cell_size = self.report.cell_fields_reports.size
      per_cell_size =  self.report.cell_fields_reports[0..cell_size-1].collect{ |c| c.percentage_weight_col_span }.compact.sum
      rows = []
      rows_values.each do |r|
        row =[]

        # row values
        (0..row_columns.size-1).each do |i|
          row << (0..cell_size-1).collect do |j|
            r_cell = r[i].clone
            if j != 0 || r_cell[:value] == 'N/A'
              r_cell[:value] = ''
              r_cell[:row_span] = 1
            end
            r_cell
          end
        end

        # cell values
        row << id_descriptions(self.report.cell_fields_reports).flatten.collect{|cell| {:value => cell[:descr], :type => :row} if cell[:id] > 0}.compact

        # data values
        header_col_size = cell_columns.size
        header_col_size /= cell_size
        (0..header_col_size-1).each do |i|
          row_cells = r[i*(cell_size+per_cell_size)+row_columns.size..(i+1)*(cell_size+per_cell_size)-1+row_columns.size]
          collect_val = []
          collect_per = []
          # separate value & percent
          if self.report.cell_location == :row && self.report.has_percentage_weight?
            j = 0
            self.report.cell_fields_reports.each do |cfr|
              collect_val << row_cells[j]

              if cfr.is_percentage_weight?
                j+=1
                collect_per << row_cells[j]
              else
                collect_per << { :value => 0, :type => :cell, :format => :percent }
              end
              j+=1
            end
          else
            collect_val = row_cells
          end

          row << collect_val unless collect_val.empty?
          row << collect_per unless collect_per.empty?
        end
        rows << row.transpose
      end
      rows_values = []
      rows.each{|r| (r.each{ |rc| rows_values << rc }) }
    end

    last_rows_count = 1
    last_rows_count = self.report.cell_fields_reports.size if self.report.cell_location == :row

    datas += rows_values.collect do |v|
      v.collect do |c|
        format = case c[:type]
        when :row then (c[:format] ||= :text)
        when :cell, :sub_total, :grand_total, :percentage then (c[:format] ||= c[:type])
        else c[:type]
        end

        if self.report.display_grand_totals.include?(:row) && rows_values[rows_values.size-last_rows_count..rows_values.size-1].include?(v)
          format = if c[:value].is_a?(Array) || format == :text || format == :sub_total_text || format == :grand_total_text
            :grand_total_text
          elsif format == :percentage || format == :sub_total_percentage || format == :grand_total_percentage
            :grand_total_percentage
          elsif format == :number_pre2 || format == :sub_total_number_pre2 || format == :grand_total_number_pre2
            :grand_total_number_pre2
          else
            :grand_total
          end
        end

        excel_wrap_data( :data, c[:value], format, c[:col_span], c[:row_span])
      end
    end

    datas
  end

  def excel_footer_data

  end

  # The data that will be written to the csv_field_sequence
  def excel_data_collection()
    info = excel_info
    filters = excel_filter
    chart = excel_chart
    headers = excel_header_data
    datas = excel_data
#    footers = excel_fotter_data

    info + filters + chart + headers + datas #+ footers
  end

  unless method_defined?(:orig_excel_format_options)
    alias_method :orig_excel_format_options, :excel_format_options
  end

  def excel_format_options
    @efo ||= orig_excel_format_options

    palette_offset = excel_palette_offset + excel_gray_scale_shared

    @efo[:header].update(:bg_color => palette_offset)
    @efo[:header_merged].update(:bg_color => palette_offset)
    
    palette_offset += ReportRequest.background_colors_24bit[:header].size
    @efo[:sub_total].update(:bg_color => palette_offset)
    @efo[:sub_total_percentage].update(:bg_color => palette_offset)
    @efo[:sub_total_number_pre2].update(:bg_color => palette_offset)
    @efo[:sub_total_text].update(:bg_color => palette_offset)
    @efo[:sub_total_merged].update(:bg_color => palette_offset)

    palette_offset += ReportRequest.background_colors_24bit[:data].size - 1
    @efo[:grand_total].update(:bg_color => palette_offset)
    @efo[:grand_total_percentage].update(:bg_color => palette_offset)
    @efo[:grand_total_number_pre2].update(:bg_color => palette_offset)
    @efo[:grand_total_text].update(:bg_color => palette_offset)
    @efo[:grand_total_merged].update(:bg_color => palette_offset)

    @efo
  end
  
  def row_columns
    @row_columns ||= id_descriptions(self.report.row_fields_reports)
  end
  
  def cell_columns(report_request_col = nil, cell_location = :col)
    if report_request_col.nil?
      col_field = self.report.col_fields_reports.first
      rrc_groups = self.col_report_request_cols(col_field)
      columns = rrc_groups[0].collect{|rrc| cell_columns(rrc, cell_location) }
      if self.report.display_grand_totals.include?(:col)
        if cell_location == :col
          columns += id_descriptions(self.report.cell_fields_reports, 'Grand Total')
        else
          columns += id_descriptions([self.report.cell_fields_reports.first], 'Grand Total')
          columns += [{:id => -self.report.cell_fields_reports.first.id, :descr => '%' }] if self.report.has_percentage_weight?
        end
      end
    else
      col_field = report_request_col.fields_report
      if col_field != self.report.col_fields_reports.last
        columns = report_request_col.childs.collect{|rrc| cell_columns(rrc, cell_location) }
        if col_field.summarize != :non
          if cell_location == :col
            columns += id_descriptions(self.report.cell_fields_reports, report_request_col)
          else
            columns += id_descriptions([self.report.cell_fields_reports.first], report_request_col)
            columns.last[0][:descr] = ''
            if self.report.has_percentage_weight?
              columns += id_descriptions([self.report.cell_fields_reports.first], report_request_col)
              columns.last[0][:descr] = '%'
              columns.last[0][:id] *= -1
            end
          end
        end
      else
        if cell_location == :col
          columns = id_descriptions(report_request_col.childs)
        else
          columns = [{ :id => report_request_col.childs.first.id, :descr => '' }]
          columns += [{:id => -report_request_col.childs.first.id, :descr => '%' }] if self.report.has_percentage_weight?
        end
      end
    end
    
    columns.flatten
  end

  def id_descriptions(arr, prefix = nil)
    arr.collect do |e|
      case prefix
      when NilClass
        e_id = e.id
        e_descr = e.full_descr
      when String
        e_id = e.id
        e_descr = "#{prefix} - #{e.full_descr}"
      else
        e_id = prefix.id
        e_descr = "#{prefix.full_descr} - #{e.full_descr}"
      end
      
      fields_report = ( e.is_a?(FieldsReport) ) ? e : e.fields_report

      a = [{ :id => e_id, :descr => e_descr }]

      if fields_report.is_percentage_weight? && self.report.cell_location == :col
        a << a.first.clone
        a.last[:id] *= -1
        a.last[:descr] = '%'
      end
      
      a
    end
  end

  def save_row(row_id, rr_row_id, reference_screen_index)
    ReportRequestRow.create(
      :row_id => row_id,
      :report_request_row_id => rr_row_id,
      :report_request_id => self.id,
      :reference_screen_index => reference_screen_index
    )
  end

  def save_column(source_id, type, rr_col_id, fields_report_id)
    "ReportRequestCols::#{type.to_s.classify}".constantize.create(
              :source_id => source_id, 
              :report_request_col_id => rr_col_id,
              :fields_report_id => fields_report_id,
              :report_request_id => self.id)
  end

  def save_cell(rr_row_id, rr_col_id, value)
    ReportRequestCell.compact(value)
    
    ReportRequestCell.create(
              :report_request_row_id => rr_row_id,
              :report_request_col_id => rr_col_id,
              :value => value)
  end

  def reload_ht_screen_rows(ht_screen_row_ids)
    ht_screen_rows = {}

    ht_screen_row_ids.each do |s_id, r_ids|
      ht_screen_rows[s_id] = {}

      n = 0
      block_size = 1000
      row_ids = r_ids[n..(n + block_size - 1)]

      while row_ids
        rows = Row.find(:all, :include => :cells, :conditions => {:rows => { :id => row_ids } })
        rows.each {|r| ht_screen_rows[s_id][r.id] = r}

        n += block_size
        row_ids = r_ids[n..(n + block_size - 1)]
      end
    end

    ht_screen_rows
  end

  def filter_screen_rows_by_field_filter(screen, screen_index)
    filters = {}
    filter_row_ids = []

    self.report.field_report_filters.each do |frf|
      next if frf.reference_screen_index != screen_index

      ff = self.field_filter(frf.reference_screen_index, frf.field_id)
      
      if ff.field_id < 0
        filter_row_ids = ff.selected_ids
      else
        case ff.field.custom_field
        when CustomFields::DateTimeField then
          if frf.filter == :long_date
            filters[ff.field.custom_field_id.to_s] = ff.value
          else
            # ToDo: Move this algorithm, on how to get the date range from the Month, Quarter, Half, Year
            # to the CustomFields::DateTimeField
            null_date = Date.null_date
          
            # Get dt_from
            case frf.filter
            when :long_month then
              month_shift = 1
              dt_from = Date.new(ff.accounting_year, ff.accounting_month, null_date.day)
            when :quarter_year then
              month_shift = 3
              dt_from = Date.new(ff.accounting_year, null_date.month, null_date.day)
              quarter_shift = (ff.accounting_month - 13) * month_shift
              dt_from = (dt_from >> quarter_shift)
            when :half_year then
              month_shift = 6
              dt_from = Date.new(ff.accounting_year, null_date.month, null_date.day)
              quarter_shift = (ff.accounting_month - 17) * month_shift
              dt_from = (dt_from >> quarter_shift)
            when :year then
              month_shift = 12
              dt_from = Date.new(ff.accounting_year, null_date.month, null_date.day)
            end
          
            dt_to = (dt_from >> month_shift) - 1
          
            filters[ff.field.custom_field_id.to_s] = {'from' => dt_from, 'to' => dt_to}
          end
        when CustomFields::Calendar
          filters[ff.field.custom_field_id.to_s] = {:selected_date => Date.new(ff.accounting_year, Date.null_date.month, Date.null_date.day) }
        else
          filters[ff.field.custom_field_id.to_s] = ff.value
        end
      end if !ff.nil?
    end

    options = Row.filter(screen.id,
      :custom_fields => filters,
      :row_ids => filter_row_ids,
      :sort_results => false,
      :include_updated_at_filter => false
    )
    
    options[:filtered_row_ids]
  end

  def fetch_chart_data
    charted_cells = self.report.cell_fields_reports.select{|c_fr| c_fr.chart_axis != :none }
    unless charted_cells.empty?

      date_format_list = (1..12).to_a
      result = {}

      rows = visible_report_request_rows.empty? ? [grand_total_row] : self.parent_report_request_rows
      
      
      rows.each do |rr_r|
        charted_cells.each do |c_fr|
          next unless [:left, :right].include?(c_fr.chart_axis)
          
          rr_cs = c_fr.report_request_cols.select{|rrc| rrc.report_request_id == self[:id] && ( rrc.date_src_report_request_col.nil? ? true : date_format_list.include?(rrc.date_src_report_request_col.source_id) ) }
          data = rr_cs.collect do |rr_c|
            cell_value = rr_c.fields_report.row_cell_values(rr_r, rr_c, rr_r.leaf_report_request_rows).first
            value = ReportRequestCell.evaluate(cell_value)
            
            case value
            when NilClass, String, Fixnum, Float
              factor = !c_fr.format[:format].nil? && c_fr.format[:format].to_sym == :percentage ? 100.0 : 1.0
              value.to_f * factor
            when Date, DateTime
              value
            else
              0
            end
          end
          
          row_descr = rr_r.full_descr unless rr_r.full_descr == 'Grand Total'
          col_descr = c_fr.field_id < 0 ? self.report.reference_screens[c_fr.reference_screen_index].label_descr : c_fr.descr if charted_cells.size > 1
          
          series_name = [row_descr, col_descr].compact.join(' - ')
          series_name = 'N/A' if series_name.strip.empty?

          result[c_fr.chart_axis] ||= []
          result[c_fr.chart_axis] << [series_name, data]
        end
      end

      result[:labels] = {}
      all_last_report_request_cols = self.report.col_fields_reports.last.report_request_cols
      last_report_request_cols = all_last_report_request_cols.select{|rrc| rrc.report_request_id == self[:id] && ( rrc.date_src_report_request_col.nil? ? true : date_format_list.include?(rrc.date_src_report_request_col.source_id) )}
      last_report_request_cols.each_with_index do |co, i|
        result[:labels][i] = co.full_descr
      end
    end

    result
  end

  def reffered_row_ids(screen_index, screens, ht_screen_row_ids)
    raise "'#{self.report.name}'s report criterias are not set" if self.report.criterias.empty? && self.report.reference_screen_ids.length > 1

    field_criterias = self.report.criterias.collect do |c|
      next unless c[:operation] == '=='

      if c[:a_screen_index] == screen_index && c[:a_field_id] < 0
        foreign_screen_index = c[:b_screen_index]
        foreign_field_id = c[:b_field_id]
      elsif c[:b_screen_index] == screen_index && c[:b_field_id] < 0
        foreign_screen_index = c[:a_screen_index]
        foreign_field_id = c[:a_field_id] 
      end
      
      {
        :foreign_screen_index => foreign_screen_index,
        :foreign_field_id => foreign_field_id
      } unless foreign_field_id.nil?
    end.compact
    
    screen_fields = {}
    field_criterias.each do |fc|
      foreign_screen_index = fc[:foreign_screen_index]
      foreign_field_id = fc[:foreign_field_id]

      field = screens[foreign_screen_index].fields.select{|f| f.id == foreign_field_id }.first
      
      screen_fields[foreign_screen_index] ||= {}
      screen_fields[foreign_screen_index][foreign_field_id] = field unless screen_fields[foreign_screen_index].has_key?(foreign_field_id)
    end
    
    row_ids = field_criterias.collect do |fc|
      field = screen_fields[fc[:foreign_screen_index]][fc[:foreign_field_id]]

      case field
      when Fields::Data then
        case field.custom_field
        when CustomFields::Reference
          values = []
          block_size = 1000
          offset = 0

          begin
            cells = Cell.find(:all,
              :joins => [:row],
              :limit => block_size,
              :offset => offset,
              :conditions => {
                :rows => { :screen_id => field.screen_id},
                :cells => { :field_id => field.custom_field_id, :row_id => ht_screen_row_ids[fc[:foreign_screen_index]] }
              }
            )

            break if cells.empty?
            
            values += cells.collect{|c| CustomFields::Reference.cell_ref_row_id(c.value) }
            values.uniq!

            offset += block_size
          end while true
          
          values
        else
          raise "Unsupported case for custom_field type #{field.custom_field.class.to_s}"
        end
      else
        raise "Unsupported case for field type #{field.class.to_s}"
      end
    end.flatten.compact.uniq

    row_ids
  end

  def data_value(rows, a_i, b_i, c, screens, ht_screen_rows, screen_index, screen_ids)
   a_value = row_data_value(rows, a_i, c[:a_field_id], screens[a_i], ht_screen_rows) if a_i < screen_ids.length
   b_value = row_data_value(rows, b_i, c[:b_field_id], screens[b_i], ht_screen_rows) if b_i < screen_ids.length

    if screen_index == screen_ids.length && a_i != b_i
      if a_i == screen_index
        screen_value = c[:b_field_id]
        screen = b_i
        value_value = c[:a_field_id]
      else
        screen_value = c[:a_field_id]
        screen = a_i
        value_value = c[:b_field_id]
      end

      field = screens[screen].fields.select{|f| f.id == screen_value }.first
      cs_field = field.custom_field

      value_value = case cs_field
      when CustomFields::NumericField
        value_value.to_f
      end

      b_value = value_value if screen == a_i
      a_value = value_value if screen == b_i
    end

    return a_value, b_value
  end

  def row_data_value(data, screen_index, field_id, screen, ht_screen_rows)
    row_id = data[screen_index]

    @row_data_value ||= {}
    @row_data_value[row_id] ||= {}
    
    unless @row_data_value[row_id][field_id]
      row = ht_screen_rows[screen_index][row_id]
      field = screen.fields.select{|f| f.id == field_id }.first

      case field
      when NilClass
        value = row.id
      when Fields::Data then
        actual_row = Field.row_by_field(field, row)
        cell = actual_row.cell(field.custom_field_id) unless actual_row.nil?
        if cell
          case field.custom_field
          when CustomFields::Reference
            value = CustomFields::Reference.cell_ref_row_id(cell.value)
          when CustomFields::LeftRight, CustomFields::ListBox, CustomFields::CheckBox, 
              CustomFields::IssueTracking, 
              CustomFields::UploadImage, CustomFields::UploadFile
            raise "Unsupported case for custom_field type #{field.custom_field.class.to_s}"
          when CustomFields::ScreenCombindedReference, 
              CustomFields::OptionCombindedReference, 
              CustomFields::CodeCombindedReference
            raise "Unsupported case for custom_field type #{field.custom_field.class.to_s}"
          when CustomFields::ComboBox, CustomFields::RadioButton
            value = CustomFields::RadioButton.cell_label_id(cell.value)
          when CustomFields::TextField, CustomFields::TextArea, 
              CustomFields::DateTimeField, 
              CustomFields::NumericField, 
              CustomFields::LoginField, 
              CustomFields::Password, CustomFields::AutoNumbering
            value = cell.absolute_value
          else
            raise "Unsupported case for custom_field type #{field.custom_field.class.to_s}"
          end
        end
      when Fields::DetailInfo
        raise "Unsupported case for field type #{field.class.to_s}"
      else
        value = field.evaluate(row)
      end unless row.nil?
      
      @row_data_value[row_id][field_id] = value
    end

    @row_data_value[row_id][field_id]
  end

  validates_presence_of :name
  validates_presence_of :report_id
  validates_presence_of :user_id
  validates_uniqueness_of :name, :scope => [:user_id]
  validates_length_of :remark, :within => 0..255
end
