require 'rubygems'
require 'writeexcel'

class ReportsController < ApplicationController
  layout nil
  helper :send_doc
  include SendDocHelper

  class << self
    def get_session_report_results(session_id, report_timestamp)
      vm = VirtualMemory::load(:session, session_id)

      vm[:report_results] ||= {}
      vm[:report_results][report_timestamp] || {}
    end

    def store_session_report_results(session_id, report_timestamp, report_results)
      vm = VirtualMemory::load(:session, session_id)

      vm[:report_results] ||= {}
      vm[:report_results][report_timestamp] = report_results

      VirtualMemory::store(:session, session_id, vm)
    end
  end # class << self

  def permission_map(action)
    'index'
  end

#  def permission_mapping
#    permission_mappings = super.merge(
#      {
#        'fetch_report' => 'index',
#        'edit' => 'index',
#        'action_daily_report' => 'action_daily',
#        'gtotal_report' => 'gtotal',
#        'rank_history_report' => 'rank_history',
#        'compare_action_report' => 'compare_action',
#        'get_reference' => 'gtotal'
#      }
#    )
#
#    %w(
#        new
#        create
#        select_alias
#        select_criterias
#        select_fields
#        formats
#        select_filters
#        set_reference_screen_alias
#        set_criterias
#        set_fields
#    ).each {|a| permission_mappings[a] = 'index'}
#
#    permission_mappings
#  end

  def screen_from_action(params)
    screen = super
    
    if screen.nil?
      if params[:screen_id].to_i > 0
        screen = Screen.find(params[:screen_id])
      elsif params[:action] == 'export'
        screen = Screen.find(params[:id])
      else
        screen = Screen.from_action(
          :controller => 'reports',
          :action => permission_map(params['action'])
        )
      end
    end
    
    screen
  end

  # GET /reports
  # GET /reports.xml
  def index
    @screen = session.active_screen
    @reports = Report.find(:all)

    @reports.sort!{|a,b| a.name <=> b.name }
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @reports }
    end
  end

  # GET /reports/fetch_row/1
  # GET /reports/fetch_row/1.xml
  def fetch_row
    @screen = session.active_screen
    @report = Report.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @report }
    end
  end

  def fetch_report
    @report = Report.find(params[:id].to_i)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @report }
    end
  end

  # GET /reports/new
  # GET /reports/new.xml
  def new
    @screen = session.active_screen
    @report = Report.new
    
    @assigned_options = []
    child_screens = Screen.find(:all,
      :conditions=>[' controller = ? and action = ?', 'screens', 'show']
    ).select{|s| !(s.is_a?(RevisionScreen) || s.is_a?(DetailScreen)) }
    @all_options = child_screens.collect{|s| s.parent }.compact.uniq.sort{|a,b| a.name <=> b.name }
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @report }
    end
  end

  # GET /reports/1/edit
  def edit
    @screen = session.active_screen
    @report = Report.find(params[:id].to_i)

    @assigned_options = @report.reference_screens
    child_screens = Screen.find(:all,
      :conditions=>[' controller = ? and action = ?', 'screens', 'show']
    ).select{|s| !(s.is_a?(RevisionScreen) || s.is_a?(DetailScreen)) }
    @all_options = child_screens.collect{|s| s.parent }.compact.uniq.sort{|a,b| a.name <=> b.name }

    clean_field_filters
  end

  # GET /reports/select_alias/1
  def select_alias
    @screen = session.active_screen
    @report = Report.find(params[:id].to_i)
  end

  # GET /reports/select_criterias/1
  def select_criterias
    @screen = session.active_screen
    @report = Report.find(params[:id].to_i)
  end

  # GET /reports/select_fields/1
  def select_fields
    @screen = session.active_screen
    @screen = session.active_screen
    @report = Report.find(params[:id].to_i)

    @reference_screens = @report.reference_screens
    
    respond_to do |format|
      format.html # new_fields.html.erb
      format.xml  { render :xml => @report }
    end
  end

  # POST /reports
  # POST /reports.xml
  def create
    @screen = session.active_screen
    @report = Report.new(params[:report])
    @report.reference_screen_alias = []
    @report.reference_screen_outer_joins = []
    @report.reference_screens.each do |s|
      a = s.label_descr.gsub(/[^A-Z]/,'').downcase
      a << "_#{@report.reference_screen_alias.select{|x| x =~ Regexp.new("(^#{a}$|^#{a}_[0-9]+$)") }.length}" if @report.reference_screen_alias.include?(a)
      @report.reference_screen_alias << a
      @report.reference_screen_outer_joins << {'-1' => false}
    end

    @report.cell_location = 'col'

    @report.save
  end

  # PUT /reports/1
  # PUT /reports/1.xml
  def update
    @screen = session.active_screen
    @report = Report.find(params[:id])
    
    params[:report]['reference_screen_ids'].each_with_index do |s_id, i|
      @report.reference_screen_outer_joins << { '-1' => false } if s_id.to_i > -1 && @report.reference_screen_outer_joins[i].nil?
    end

    params[:report]['reference_screen_outer_joins'] = @report.reference_screen_outer_joins

    @report.update_attributes(params[:report])

    clean_field_filters

    respond_to do |format|
      format.html # update.html.erb
      format.xml  { render :xml => @report }
    end
  end

  # DELETE /reports/1
  # DELETE /reports/1.xml
  def destroy
    @report = Report.find(params[:id].to_i)
    ActiveRecord::Base.transaction do
      @report.destroy
    end
  end
  # POST /reports
  # POST /reports.xml
  def set_reference_screen_alias
    @screen = session.active_screen
    @report = Report.find(params[:id])

    params[:report] ||= {}
    params[:report][:reference_screen_alias] ||= {}

    @report.reference_screen_alias = []
    @report.reference_screen_outer_joins = []
    
    @report.reference_screens.each_with_index do |s, i|
      a = s.label_descr.gsub(/[^A-Z]/,'').downcase
      a << "_#{@report.reference_screen_alias.select{|x| x =~ Regexp.new("(^#{a}$|^#{a}_[0-9]+$)") }.length}" if @report.reference_screen_alias.include?(a)
      @report.reference_screen_alias << (params[:report][:reference_screen_alias][i.to_s] || a)
      @report.reference_screen_outer_joins << params[:report][:reference_screen_outer_joins][i.to_s]
    end

    @report.save
  end

  # POST /reports
  # POST /reports.xml
  def set_criterias
    @screen = session.active_screen
    @report = Report.find(params[:id])
    ref_screen_count = @report.reference_screen_ids.size
    params[:report] ||= {}
    params[:report][:criterias] ||= []

    params[:report][:criterias].delete_if do |c|
      c[:a_screen_index].nil? ||
        (c[:a_screen_index].to_i < ref_screen_count && c[:a_field_id].to_i == 0) ||
        c[:b_screen_index].nil? ||
        (c[:b_screen_index].to_i < ref_screen_count && c[:b_field_id].to_i == 0) ||
        c[:operation].to_s.empty?
    end

    params[:report][:criterias].each do |c|
      c[:a_screen_index] = c[:a_screen_index].to_i
      c[:a_field_id] = c[:a_field_id].to_i if c[:a_screen_index] < ref_screen_count
      c[:b_screen_index] = c[:b_screen_index].to_i
      c[:b_field_id] = c[:b_field_id].to_i if c[:b_screen_index] < ref_screen_count
    end

    @report.criterias = params[:report][:criterias]
    @report.save
  end

  # POST /reports
  # POST /reports.xml
  def set_fields
    @screen = session.active_screen
    @report = Report.find(params[:id])

    params[:report] ||= {}
    params[:report][:fields] ||= []

    org_field_report = @report.fields_reports
    new_field_reports = params[:report][:fields]

    #remove not exist in new
    rem_field_report_ids = org_field_report.collect{|fr| fr.id}.compact - new_field_reports.collect{|f_r| f_r[:field_report_id].to_i unless f_r[:field_report_id].empty?}.compact
    org_field_report.each do |fr|
      fr.destroy if rem_field_report_ids.include?(fr.id)
    end unless rem_field_report_ids.empty?

    # merge field_report
    new_field_reports.each_with_index do |f_r, idx|
      f_r[:seq_no] = idx
      f_r['formula'] = YAML::load(f_r['formula'].gsub('^n',"\n")) unless f_r['formula'].empty?
      field_report_id = f_r.delete(:field_report_id).to_i
      if field_report_id == 0
        f_r['percentage_weight'] = {'-1' => 'false'}
        
        @report.fields_reports << FieldsReport.new(f_r)
      else
        field_report = FieldsReport.find(field_report_id)
        field_report.update_attributes(f_r)
      end
    end

    ht_report = {}
    ht_report[:cell_location] = params[:report][:cell_location]
    
    @report.update_attributes(ht_report)
  end

  # GET /reports
  # GET /reports.xml
  def formats
    @screen = session.active_screen
    @report = Report.find(params[:id])

    respond_to do |format|
      format.html # formats.html.erb
      format.xml  { render :xml => @report }
    end
  end

  # GET /reports
  # GET /reports.xml
  def select_filters
    @screen = session.active_screen
    @report = Report.find(params[:id])
    @available_field_filters =  @report.fields_for_filters
    @set_field_filters = {}
    @report.field_report_filters.each{|frf|
      @set_field_filters[frf.reference_screen_index] ||= {}
      @set_field_filters[frf.reference_screen_index][frf.field_id] = frf
    }

    respond_to do |format|
      format.html # formats.html.erb
      format.xml  { render :xml => @report }
    end
  end
 
  # GET /reports/1
  def edit_format
    @report = Report.find(params[:id])
    @field_report = FieldsReport.find(params[:field_report_id])
    @labels = Label.find(:all).sort{|a,b| a.descr <=> b.descr }
    
    respond_to do |format|
      format.html # edit_format.html.erb
      format.xml  { render :xml => @report }
    end
  end

  # PUT /reports/update_format
  # PUT /reports/update_format/1.xml
  def update_format
    @screen = session.active_screen
    @field_report = FieldsReport.find(params[:id]) 

    @field_report.update_attributes(params[:field_report])
    
    respond_to do |format|
      format.html # update_format.html.erb
      format.xml  { render :xml => @report }
    end
  end
  
  def edit_filter
    field_report_filter_id = params[:id]
    
    if field_report_filter_id =~ /_/
      @field_report_filter = FieldReportFilter.new(
        :report_id => params[:report_id],
        :field_id => params[:field_id],
        :reference_screen_index => params[:reference_screen_index]
      )
    else
      @field_report_filter = FieldReportFilter.find(field_report_filter_id.to_i)
    end

    respond_to do |format|
      format.html # edit_format.html.erb
      format.xml  { render :xml => @report }
    end
  end

  # PUT /reports/update_format
  # PUT /reports/update_format/1.xml
  def update_filter
    @screen = session.active_screen
    field_report_filter_id = params[:id]
    
    if field_report_filter_id =~ /_/
      # Create
      @field_report_filter = FieldReportFilter.create(
        :reference_screen_index => params[:reference_screen_index],
        :field_id => params[:field_id],
        :report_id => params[:report_id],
        :value => params[:value])
    else
      @field_report_filter = FieldReportFilter.find(field_report_filter_id.to_i)
      
      if params.has_key?(:destroy)
        # Delete
        @field_report_filter.destroy
      else
        # Update
        @field_report_filter.value = params[:value]
        @field_report_filter.save
      end
    end
    @set_field_filters = {
      @field_report_filter.reference_screen_index => { @field_report_filter.field_id => @field_report_filter }
    }
    @available_field_filters =  @field_report_filter.report.fields_for_filters

    respond_to do |format|
      format.html # edit_format.html.erb
      format.xml  { render :xml => @field_report_filter }
    end
  end

  def clean_field_filters
    @report = Report.find(params[:id].to_i)

    @report.field_report_filters.each{|frf|
      ref_screen = @report.reference_screens[frf.reference_screen_index]
      if ref_screen.nil? || ref_screen.field(frf.field_id).nil?
        field_report_filter = FieldReportFilter.find(frf.id)
        field_report_filter.destroy
      end
    }
  end 
  
  def export
    @screen_id = params[:id]
    @parent_row_id = params[:parent_row_id]
    @header_row_id = params[:header_row_id]
    @action_source = params[:action_source]
  end

  def generate
    screen = Screen.find(params['screen_id']).nil? ? 'unknown_screen' : Screen.find(params['screen_id']) 
    
    vm = VirtualMemory::load(:session, session.session_id)
    
    case params[:data_size].to_sym
    when :filter_wo_limit
      vm[:filtered_row_ids_wo_limit] ||= {}
      row_ids = vm[:filtered_row_ids_wo_limit][screen.id]
    when :all
      row_ids = screen.row_ids
    else
      vm[:filtered_row_ids] ||= {}
      row_ids = vm[:filtered_row_ids][screen.id]
    end || []
    
    rows = Row.find(:all, :conditions => [' id in (?)', row_ids]) #screen.rows
	  if params['report_type'][:report_type] == 'PDF'
		  pdf_report(rows)
	  elsif params['report_type'][:report_type] == 'XLS'
		  excel_report(rows)
	  elsif params['report_type'][:report_type] == 'CSV'
		  csv_report(rows)
	  end
    date = Time.now.strftime('%Y%m%d')
    time = Time.now.strftime('%H:%M:%S:')
    logfile = File.new("#{RAILS_ROOT}/public/LogFile/log#{date}.log",'a+')
    logfile.puts "#{date} #{time} #{User.find(session['user_id'])['login']} export #{screen.nil? ? 'unknown_screen' : screen.name.gsub(' ','_')}_Screen -"
    logfile.close
  end

  def pdf_report(rows)
    #	  @screen = Screen.find(params[:screen_id])
    #    @header_row_id = params[:header_row_id]
    #	  @xml_string = @screen.generate_xml(rows,header_row_id)
    #	  send_doc(@xml_string ,'/row_result/cell_value/cell', 'cell', 'Report', 'pdf')
  end
  
  def excel_report(rows)
	  file_path,time = xls(rows)
    file_names = Dir.new("#{RAILS_ROOT}/public/ReportFile/").entries
    file_names.each do |file_name|
      if (file_name != '.') && (file_name != '..') && (file_name != '.svn') && !(file_name.include?(time))
        begin
          File.delete("#{RAILS_ROOT}/public/ReportFile/#{file_name}")
        rescue Exception
          # Nothing to do
        end
      end
    end
    send_file(file_path, :disposition => 'attachment', :encoding => 'utf8', :type => 'application/octet-stream')
  end
  def csv_report(rows)
	  csv_data, file_name = csv(rows)

    tmp_file_path = File.join(RAILS_ROOT, 'tmp', 'cache', 'rpt', "#{Time.now.to_f.to_s.gsub('.', '')}.tmp")
    File.open(tmp_file_path, 'w') do |f|
      f.puts csv_data
    end

#    File.delete(tmp_file_path)

	  send_file tmp_file_path, :filename => file_name, :disposition => 'attachment', :type => 'text/csv'
  end

  def xls(rows)

    # XLS File Name
    screen = Screen.find(params[:screen_id])
    time = Time.now.strftime('%Y%m%d%H%M')
    file_name = "#{screen.name}_#{time}".gsub(' ','_').gsub('/','')
	  file_path = "#{RAILS_ROOT}/public/ReportFile/#{file_name}.xls"
    workbook  = Spreadsheet::WriteExcel.new(file_path) 
    worksheet = workbook.add_worksheet
    header_format = workbook.add_format(:border => 1, :bold => 1, :color => 'black', :bg_color => 27, :merge => 1, :align => 'vcenter')
	  data_format = workbook.add_format(:border => 1, :color => 'black', :size => 10)
    group_format = workbook.add_format(:border => 1, :bold => 1, :bg_color => 27 , :valign => 'vcenter', :align => 'center')
    
    display_flag_label = Label.find_by_name('G_List')
    fields = []
    custom_field_ids = []
    screen.fields.each do |field|
      if field.display_in_screen?(display_flag_label)
        fields << field
        custom_field_ids << field.custom_field_id
      end
    end

    custom_field_ids.compact!

    # XLS Header
    line = 0
    column = 0
    childs = []
    col = 0
    max_col = {}
    for i in 1..screen.field_level
      if screen.is_a?(RevisionScreen) and i == 1
        if screen.field_level!=1
          worksheet.merge_range(line,column,line+screen.field_level-1,column, 'Rev No',group_format)
        else
          worksheet.write(line,column,'Rev No',header_format)
        end
        column += 1
      end
      
      headers = []
      if screen.is_a?(DetailScreen)
        screen.revision_screen.header_screen.fields.each do |f|
          descrs = []
          descrs = [f.descr()].flatten if (f.display_in_list? || f.is_a?(Fields::Data)) or f.is_a?(Fields::Grouping)
          headers += descrs.collect{|d|{:descr => d,:col_span => f.col_span(:row_pattern =>@row_pattern),:row_span => f.row_span}}
        end
        screen.revision_screen.fields.each do |f|
          descrs = []
          descrs = [f.descr()].flatten if (f.display_in_list? || f.is_a?(Fields::Data)) or f.is_a?(Fields::Grouping)
          headers += descrs.collect{|d|{:descr => d,:col_span => f.col_span(:row_pattern =>@row_pattern),:row_span => f.row_span}}
        end
      elsif screen.is_a?(RevisionScreen)
        screen.header_screen.fields.each do |f|
          descrs = []
          descrs = [f.descr()].flatten if (f.display_in_list? || f.is_a?(Fields::Data)) or f.is_a?(Fields::Grouping)
          headers += descrs.collect{|d|{:descr => d,:col_span => f.col_span(:row_pattern =>@row_pattern),:row_span => f.row_span}}
        end
      end
      
      screen.list_fields_level(i).each_with_index do |f, index|
        descrs = []
        descrs = [f.descr(:row_pattern =>@row_pattern)].flatten if (f.display_in_list? || f.is_a?(Fields::Data)) or f.is_a?(Fields::Grouping)
        if f.custom_field.is_a?(CustomFields::Calendar)
          case f.custom_field.format
          when :monthly   
            start_date = CustomFields::DateTimeField.begin_of_period(Date.null_date, :year)
            end_date = CustomFields::DateTimeField.end_of_period(Date.null_date, :year)

            diff_year =  start_date.year != end_date.year
            headers += [{:descr => 'Date',:col_span => f.col_span(:row_pattern =>@row_pattern),:row_span => f.row_span}]
            while(start_date <= end_date)
              headers += [{:descr => 'Date',:col_span => f.col_span(:row_pattern =>@row_pattern),:row_span => f.row_span}] if (start_date == end_date.beginning_of_year) && diff_year
              headers += [{:descr => start_date.strftime('%b'),:col_span => f.col_span(:row_pattern =>@row_pattern),:row_span => f.row_span}]
              start_date = start_date.next_month
            end
          end
        else 
          headers += descrs.collect{|d|{:descr => d,:col_span => f.col_span(:row_pattern =>@row_pattern),:row_span => f.row_span}}
        end

        unless f.childs.empty?
          if childs.empty?
            childs += [{:field => f.childs.first,:column => col}]
          else
            childs.each do |c|
              childs += c[:field].eql?(f) ? [{:field => f.childs.first,:column => c[:column]}] : [{:field => f.childs.first,:column => col}]
            end
          end
        end
        col += headers[index][:col_span]
      end 

      if screen.is_a?(HeaderScreen)
        if screen.revision_screen.control_revision?
          screen.revision_screen.fields.each do |f|
            if f.display_in_header_list?
              descrs = []
              descrs = [f.descr()].flatten if (f.display_in_list? || f.is_a?(Fields::Data)) or f.is_a?(Fields::Grouping)
              headers += descrs.collect{|d|{:descr => d,:col_span => f.col_span(:row_pattern =>@row_pattern),:row_span => f.row_span}}
            end
          end
        else
          screen.revision_screen.fields.each do |f|
            descrs = []
            descrs = [f.descr()].flatten if (f.display_in_list? || f.is_a?(Fields::Data)) or f.is_a?(Fields::Grouping)
            headers += descrs.collect{|d|{:descr => d,:col_span => f.col_span(:row_pattern =>@row_pattern),:row_span => f.row_span}}
          end
        end
      end

      unless childs.empty?
        screen.list_fields_level(i).each do |f|
          column = childs.first[:column] if childs.first[:field].eql?(f)
        end
        screen.list_fields_level(i).each do |f|
          childs.delete_if{|c| c[:field].eql?(f) }
        end
      end

      column = 3 if screen.is_a?(DetailScreen) and i == 2
      headers.each do |h|

        set_max_col(max_col, column, h[:descr])

        if h[:row_span]!=1 or h[:col_span]!=1
          worksheet.merge_range(line,column,line+h[:row_span]-1,column+h[:col_span]-1, (h[:descr] =~ /&nbsp;/) ? h[:descr] : h[:descr].to_s.titleize, group_format)
        else
          worksheet.write(line,column,(h[:descr] =~ /&nbsp;/) ? h[:descr] : h[:descr].to_s.titleize,header_format)
        end
        column += h[:col_span]
      end

      if screen.field_level!=1
        if (screen.is_a?(HeaderScreen) and i == 1)
          worksheet.merge_range(line,column, line+screen.field_level-1, column, 'Latest Rev no', group_format)
          column += 1
        end
        worksheet.merge_range(line,column, line+screen.field_level-1, column, 'Remark', group_format) if i == 1
      else
        if (screen.is_a?(HeaderScreen) and i == 1)
          worksheet.write(line, column, 'Latest Rev no', header_format)
          column += 1
        end
        worksheet.write(line, column, 'Remark', header_format) if i == 1
      end

      line += 1
      column = 0
      col = 0
      
    end

    # Checking field Screen
    header_fields = []
    revision_fields = []
    if screen.is_a?(DetailScreen)
      revision_fields = screen.revision_screen.fields.collect{|f| f if (f.display_in_list? || f.is_a?(Fields::Data)) or f.is_a?(Fields::Grouping)}.compact
      header_fields = screen.revision_screen.header_screen.fields.collect{|f| f if (f.display_in_list? || f.is_a?(Fields::Data)) or f.is_a?(Fields::Grouping)}.compact
    elsif screen.is_a?(RevisionScreen)
      header_fields = screen.header_screen.fields.collect{|f| f if (f.display_in_list? || f.is_a?(Fields::Data)) or f.is_a?(Fields::Grouping)}.compact
    elsif screen.is_a?(HeaderScreen)
      if screen.revision_screen.control_revision?
        revision_fields = screen.revision_screen.fields.collect{|f| f if f.display_in_header_list?}.compact
      else
        revision_fields = screen.revision_screen.fields.collect{|f| f if (f.display_in_list? || f.is_a?(Fields::Data)) or f.is_a?(Fields::Grouping)}.compact
      end
    end
    # XLS Data
    rows.each do |row|
      if row.is_a?(DetailRow) and screen.is_a?(DetailScreen)
        header_row = row.revision_row.header_row
        header_fields.each do |h_field|
          custom_field = h_field.custom_field
          cell = header_row.cell(custom_field.id) unless custom_field.nil?
          data = gen_data_xls(h_field, cell, header_row)
          data = remove_reserve_character(data.to_s) if !data.nil?
          worksheet.write(line,column,data,data_format)
          column += 1
        end

        revision_row = row.revision_row
        revision_fields.each do |r_field|
          custom_field = r_field.custom_field
          cell = revision_row.cell(custom_field.id) unless custom_field.nil?
          data = gen_data_xls(r_field, cell, revision_row)
          data = remove_reserve_character(data.to_s) if !data.nil?
          worksheet.write(line,column,data,data_format)
          column += 1
        end

        data = revision_row.rev_no.to_s
        worksheet.write(line,column,data,data_format)
        column += 1
      elsif row.is_a?(RevisionRow) and screen.is_a?(RevisionScreen)
        data = row.rev_no.to_s
        worksheet.write(line,column,data,data_format)
        column += 1
        header_row = row.header_row
        header_fields.each do |h_field|
          custom_field = h_field.custom_field
          cell = header_row.cell(custom_field.id) unless custom_field.nil?
          data = gen_data_xls(h_field, cell, header_row)
          data = remove_reserve_character(data.to_s) if !data.nil?
          worksheet.write(line,column,data,data_format)
          column += 1
        end
      end 

      fields.each do |field|
        if field.custom_field.is_a?(CustomFields::Calendar)
          custom_field = field.custom_field
          cell = row.cell(custom_field.id) unless custom_field.nil?
          detail_fields = cell.field.detail_screen.fields.select{|field| field.display_in_list? }
          display_label = detail_fields.length > 1
          selected_date = cell.value[:selected_date].to_date
          start_date = CustomFields::DateTimeField.begin_of_period(selected_date, :year)
          end_date = CustomFields::DateTimeField.end_of_period(selected_date, :year)
          diff_year =  start_date.year != end_date.year
          data = start_date.year.to_s
          worksheet.write(line,column,data,data_format)
          column += 1

          cell.calendar_values.each do |calendar_value|
            cell_data = ''
            if (start_date == end_date.beginning_of_year) && diff_year
              data = start_date.year.to_s
              worksheet.write(line,column,data,data_format)
              column += 1
            end
            cell_data << detail_fields.collect do |detail_field|

              case detail_field
              when Fields::Data
                actual_row = Field.row_by_field(detail_field, calendar_value.row)
                cv_cell = actual_row.cell(detail_field.custom_field_id) unless actual_row.nil?
                data = gen_data_xls(detail_field, cv_cell, row).to_s
                data = remove_reserve_character(data.to_s) if !data.nil?
              else
                data = detail_field.evaluate_value(calendar_value.row).to_s
              end

              "#{detail_field.label_descr + ' : ' if display_label}#{data}, "
            end.join
            cell_data.gsub!(/, $/, '')
            worksheet.write(line,column,cell_data,data_format)

            set_max_col(max_col, column, cell_data)

           column += 1
            start_date = start_date = start_date.next_month
          end

        elsif !field.is_a?(Fields::Grouping)
          data = ''
          custom_field = field.custom_field
          cell = row.cell(custom_field.id) unless custom_field.nil?
          data = gen_data_xls(field, cell, row)
          data = remove_reserve_character(data.to_s) if !data.nil?
          worksheet.write(line,column,data,data_format)

          set_max_col(max_col, column, data)

          column += 1
        end
      end
      
      max_col.each do |col, length|
        worksheet.set_column(col, col, length)
      end
      
      if row.is_a?(HeaderRow) and screen.is_a?(HeaderScreen)
        revision_row = row.latest_revision
        revision_fields.each do |r_field|
          custom_field = r_field.custom_field
          cell = revision_row.cell(custom_field.id) unless custom_field.nil?

          next if (screen.revision_screen.control_revision? && !r_field.display_in_header_list?)

          data = gen_data_xls(r_field, cell, revision_row)
          data = remove_reserve_character(data.to_s) if !data.nil?
          worksheet.write(line,column,data,data_format)
          column += 1
        end
        data = row.latest_revision_no.to_s
        worksheet.write(line,column,data,data_format)
        column += 1
      end

      remark = ''
      remark = remove_reserve_character(row.remark) if !(row.remark).nil?
      worksheet.write(line,column,remark,data_format)
      column = 0
      line += 1
    end
    workbook.close
    return file_path,'_'+time
  end

  def set_max_col(max_col, column, data)    
    max_col[column.to_i] =  [2, max_col[column.to_i].to_i, data.to_s.length].max
  end

  def csv(rows)

    # CSV File Name
	  screen = Screen.find(params[:screen_id])
	  time = Time.now.strftime('%Y%m%d%H%M')
	  file_name = "#{screen.name}_#{time}.csv".gsub(' ','_')

    display_flag_label = Label.find_by_name('G_List')
    fields = []
    custom_field_ids = []
    screen.fields.each do |field|
      if field.display_in_screen?(display_flag_label)
        fields << field
        custom_field_ids << field.custom_field_id if field.is_a?(Fields::Data)
      end
    end

    headers = []
    
    headers << '[Rev No]' if screen.is_a?(RevisionScreen)
    
    if screen.is_a?(DetailScreen)
      screen.revision_screen.header_screen.fields.each do |f|
        if  (f.display_in_list? || f.is_a?(Fields::Data)) && !f.is_a?(Fields::Grouping)
          headers << f.csv_header
        end
      end
      screen.revision_screen.fields.each do |f|
        if  (f.display_in_list? || f.is_a?(Fields::Data)) && !f.is_a?(Fields::Grouping)
          headers << f.csv_header
        end
      end
    elsif screen.is_a?(RevisionScreen)
      screen.header_screen.fields.each do |f|
        if  (f.display_in_list? || f.is_a?(Fields::Data)) && !f.is_a?(Fields::Grouping)
          headers << f.csv_header
        end
      end
    end
    fields.each do |f|
      if f.custom_field.is_a?(CustomFields::Calendar)

        cell = rows.first.cells.select{|c| c.custom_field.is_a?(CustomFields::Calendar)}.first
        detail_fields = cell.field.detail_screen.fields.select{|field| field.display_in_list? }
        selected_date = cell.value[:selected_date].to_date
        start_date = CustomFields::DateTimeField.begin_of_period(selected_date, :year)
        end_date = CustomFields::DateTimeField.end_of_period(selected_date, :year)

        diff_year =  start_date.year != end_date.year
        headers << '[Date]'

        cell.calendar_values.each do |calendar_value|
          headers << '[Date]' if (start_date == end_date.beginning_of_year) && diff_year
          detail_fields.each do |detail_field|
            headers << "[#{f.full_descr} #{calendar_value.date_time.strftime('%b')} #{detail_field.full_descr}]"
          end
          start_date = start_date.next_month
        end

      elsif (f.display_in_list? || f.is_a?(Fields::Data)) && !f.is_a?(Fields::Grouping)
        headers << f.csv_header
      end
    end
    if screen.is_a?(HeaderScreen)
      if screen.revision_screen.control_revision?
        screen.revision_screen.fields.each do |f|
          if f.display_in_header_list?
            if !f.is_a?(Fields::Grouping)
              headers << f.csv_header
            elsif  (f.display_in_list? || f.is_a?(Fields::Data)) && !f.is_a?(Fields::Grouping) and !f.field_id.nil?
              headers << f.csv_header
            end
          end
        end
      else
        screen.revision_screen.fields.each do |f|
          if  (f.display_in_list? || f.is_a?(Fields::Data)) && !f.is_a?(Fields::Grouping)
            headers << f.csv_header
          end
        end
      end
    end
    
    headers << '[Latest Rev No]' if screen.is_a?(HeaderScreen)
    headers << '[Remark]'
    
    csv_data = headers.join(',')
    csv_data << "\n"

    # Checking field Screen
    header_fields = []
    revision_fields = []
    if screen.is_a?(DetailScreen)
      revision_fields = screen.revision_screen.fields.collect{|f| f if (f.display_in_list? || f.is_a?(Fields::Data)) or f.is_a?(Fields::Grouping)}.compact
      header_fields = screen.revision_screen.header_screen.fields.collect{|f| f if (f.display_in_list? || f.is_a?(Fields::Data)) or f.is_a?(Fields::Grouping)}.compact
    elsif screen.is_a?(RevisionScreen)
      header_fields = screen.header_screen.fields.collect{|f| f if (f.display_in_list? || f.is_a?(Fields::Data)) or f.is_a?(Fields::Grouping)}.compact
    elsif screen.is_a?(HeaderScreen)
      if screen.revision_screen.control_revision?
        revision_fields = screen.revision_screen.fields.collect{|f| f if f.display_in_header_list?}.compact
      else
        revision_fields = screen.revision_screen.fields.collect{|f| f if (f.display_in_list? || f.is_a?(Fields::Data)) or f.is_a?(Fields::Grouping)}.compact
      end
    end
    # CSV Data
    rows.each do |row|

      #####
      if row.is_a?(DetailRow) and screen.is_a?(DetailScreen)
        header_row = row.revision_row.header_row
        header_fields.each do |h_field|
          custom_field = h_field.custom_field
          cell = header_row.cell(custom_field.id) unless custom_field.nil?
          data = gen_data_csv(h_field, cell, header_row)
          data = remove_reserve_character(data.to_s) if !data.nil?
          csv_data << data unless data.nil?
          csv_data << ','
        end

        revision_row = row.revision_row
        revision_fields.each do |r_field|
          custom_field = r_field.custom_field
          cell = revision_row.cell(custom_field.id) unless custom_field.nil?
          data = gen_data_csv(r_field, cell, revision_row)
          data = remove_reserve_character(data.to_s) if !data.nil?
          csv_data << data unless data.nil?
          csv_data << ','
        end

        data = revision_row.rev_no.to_s
        csv_data << data unless data.nil?
        csv_data << ','
      elsif row.is_a?(RevisionRow) and screen.is_a?(RevisionScreen)
        data = row.rev_no.to_s
        csv_data << data unless data.nil?
        csv_data << ','
        header_row = row.header_row
        header_fields.each do |h_field|
          custom_field = h_field.custom_field
          cell = header_row.cell(custom_field.id) unless custom_field.nil?
          data = gen_data_csv(h_field, cell, header_row)
          data = remove_reserve_character(data.to_s) if !data.nil?
          csv_data << data unless data.nil?
          csv_data << ','
        end
      end

      fields.each do |field|
        if field.custom_field.is_a?(CustomFields::Calendar)
          custom_field = field.custom_field
          cell = row.cell(custom_field.id) unless custom_field.nil?
          detail_fields = cell.field.detail_screen.fields.select{|field| field.display_in_list? }
          selected_date = cell.value[:selected_date].to_date
          start_date = CustomFields::DateTimeField.begin_of_period(selected_date, :year)
          end_date = CustomFields::DateTimeField.end_of_period(selected_date, :year)

          diff_year =  start_date.year != end_date.year
          
          csv_data << start_date.year.to_s
          csv_data << ','
          
          cell.calendar_values.each do |calendar_value|
            if (start_date == end_date.beginning_of_year) && diff_year
              csv_data << start_date.year.to_s
              csv_data << ','
            end

            detail_fields.each do |detail_field|             
              csv_data << case detail_field 
              when Fields::Data
                actual_row = Field.row_by_field(detail_field, calendar_value.row)
                actual_row.cell(detail_field.custom_field_id).value unless actual_row.nil?
              else
                detail_field.evaluate_value(calendar_value.row).to_s
              end
              csv_data << ','
            end 
            start_date = start_date = start_date.next_month
          end
        
        elsif !field.is_a?(Fields::Grouping)
          data = ''
          custom_field = field.custom_field
          cell = row.cell(custom_field.id) unless custom_field.nil?
          data = gen_data_csv(field, cell, row)
          data = remove_reserve_character(data.to_s) if !data.nil?
          csv_data << data unless data.nil?
          csv_data << ','

          if row.is_a?(HeaderRow) and screen.is_a?(HeaderScreen)
            revision_row = row.latest_revision
            revision_fields.each do |r_field|
              custom_field = r_field.custom_field
              cell = revision_row.cell(custom_field.id) unless custom_field.nil?

              next if (screen.revision_screen.control_revision? && !r_field.display_in_header_list?)

              data = gen_data_csv(r_field, cell, revision_row)
              data = remove_reserve_character(data.to_s) if !data.nil?
              csv_data << data unless data.nil?
              csv_data << ','
            end
            data = row.latest_revision_no.to_s
            csv_data << data unless data.nil?
            csv_data << ','
          end

        end

      end

      remark = ''
      remark = remove_reserve_character(row.remark) if !(row.remark).nil?
      csv_data << remark
      csv_data << "\n"
    end

	  return csv_data,file_name
    
  end

  def remove_reserve_character(data)
    if !data.nil?
      data = data.gsub("\n",'')
      data = data.gsub("\r",'')
      data = data.gsub(',','')
    end
  end

  # ================================
  def get_all_screen
    gen_rows = {}
    screens = Screen.find(:all)
    screens.each do |s|
      gen_rows[s.name.downcase] = s if gen_rows[s.name.downcase].nil?
    end
    return gen_rows
  end
  
  def get_all_customfield
    gen_rows = {}
    customefields = CustomField.find(:all)
    customefields.each do |cf|
      gen_rows[cf.name.downcase] = cf if gen_rows[cf.name.downcase].nil?
    end
    return gen_rows
  end
  
  def get_name_for_rank_value(value,rank_names_and_scores)
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/
  end
  def get_custom_field_id_by_name(custom_field_name)
    result = CustomField.find(:first, :conditions => ['name = ?', custom_field_name])
    return result.id
  end
  def get_reference
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/
  end
  def product_type(id)
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/
  end
  def cust_rank(id)
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/
  end
  def company_branch_hash(id, branch_ref, staff_screen, cf_company)
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/
  end  
  def company_branch(id)
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/
  end
  def company_branch_id(id)
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/
  end
  def cust_new(firstPO, dfrom)
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/
  end

  # ====== Grand Total Report with Export ======
  def gtotal
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/
  end
  
  def gtotal_report
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/
  end
  def gtotal_by_rpt(rpt_ref)
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/

    unless params['export'] == 'yes'
      #Grand Total for Nation, Business Type, Province, Estate
      business_record_screen = Screen.find(:first, :conditions => ['name = ?', 'Business Record' ])
      invoice_date_custom_field_id = get_custom_field_id_by_name('Invoice Date')
      invoice_amount_custom_field_id = get_custom_field_id_by_name('Invoice Amount')
      issue_custom_field_id = get_custom_field_id_by_name('Issue Tracking')
      customer_custom_field_id = get_custom_field_id_by_name('Customer_REF')
      product_type_custom_field_id = get_custom_field_id_by_name('Production_Type_REF')
      rpt_custom_field_id = get_custom_field_id_by_name(rpt_ref)
      potential_rank_custom_field_id = get_custom_field_id_by_name('Potential_Rank_REF')
      selected_item = params[:filter_item].to_i
      report_data = {}
      report_total = {}
      report_gtotal = 0.0

      #convert(datetime, cast(cells.value as nvarchar), 120) ===> Convert Text to NVARCHAR to DATETIME in SQL Server
      filtered_rows_by_invoice_date =  business_record_screen.rows.find(:all, :joins => [:cells],
        :conditions => ['cells.field_id = ? and cells.value between ? and  ?', invoice_date_custom_field_id, params[:invoice_from], params[:invoice_to]])

      gen_rows = gen_rows_by_fields(filtered_rows_by_invoice_date,[customer_custom_field_id,product_type_custom_field_id,invoice_amount_custom_field_id,issue_custom_field_id])
      filtered_rows_by_invoice_date.each do |r|
        value = gen_rows[r.id]
        gen_rows.delete(r.id) if CustomFields::IssueTracking.cancelled?(value[issue_custom_field_id])
      end

      cust_row_ids = gen_rows.values.collect{|value| CustomFields::Reference.cell_ref_row_id(value[customer_custom_field_id]) }.select{|r_id| r_id > 0}.uniq
      cust_rows = Row.find(cust_row_ids)
      cust_gen_rows = gen_rows_by_fields(cust_rows,[rpt_custom_field_id,potential_rank_custom_field_id])

      gen_rows.each_value do |value|
        next if (customer_id = CustomFields::Reference.cell_ref_row_id(value[customer_custom_field_id])) == 0
        next if (product_type_id = CustomFields::Reference.cell_ref_row_id(value[product_type_custom_field_id])) == 0

        amount = value[invoice_amount_custom_field_id]
        item = CustomFields::Reference.cell_ref_row_id(cust_gen_rows[customer_id][rpt_custom_field_id])
        item = 'N/A' if item == 0
        next if (potential_rank_id = CustomFields::Reference.cell_ref_row_id(cust_gen_rows[customer_id][potential_rank_custom_field_id])) == 0

        if (item != 0) && (item == selected_item.to_i || selected_item == 0)
          report_data[item] = {} if report_data[item].nil?
          report_total[item] = 0.0 if report_total[item].nil?
          report_data[item][potential_rank_id] = {} if report_data[item][potential_rank_id].nil?
          report_data[item][potential_rank_id][customer_id] = {} if report_data[item][potential_rank_id][customer_id].nil?
          report_data[item][potential_rank_id][customer_id][product_type_id] = 0.0 if report_data[item][potential_rank_id][customer_id][product_type_id].nil?
          report_data[item][potential_rank_id][customer_id][product_type_id] += amount.to_f
          report_total[item] += amount.to_f
          report_gtotal += amount.to_f
        end
      end
      ReportsController.store_session_report_results(session.session_id, '',
        {
          :report_data => report_data,
          :report_total => report_total,
          :report_gtotal => report_gtotal
        })
    else
      vm = ReportsController.get_session_report_results(session.session_id, '')
      report_data = vm[:report_data]
      report_total = vm[:report_total]
      report_gtotal = vm[:report_gtotal]
      
      export_grand_total(rpt_ref.gsub('_REF',''),[rpt_ref.gsub('_REF',''),'Potential Rank','Customer','Product Type','Amount'],report_data, report_total, report_gtotal, params[:invoice_from], params[:invoice_to])
    end
    
    return report_data, report_total, report_gtotal
  end
  def gtotal_by_area
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/
  end
  def gtotal_by_rank
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/
  end
  def gtotal_by_sales_product(rpt_type)
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/
  end
  
  def gtotal_by_bill_count
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/
  end

  def export_grand_total(name,headers,report_data,report_total,report_gtotal,dfrom, dto)
    time = Time.now.strftime('%Y%m%d%H%M%S')
	  file_name = "#{name}_#{time}".gsub(' ','_')
	  file_path = "#{RAILS_ROOT}/public/ReportFile/#{file_name}.xls"
	  workbook  = Spreadsheet::WriteExcel.new(file_path);
	  format_title = workbook.add_format(:bold => 1,:color => 'black', :size => 14,:merge => 5)
	  format_header = workbook.add_format(:bold => 1,:color => 'black', :bg_color => 27 ,:size => 12,:merge => 1,:align => 'vcenter')
	  format_data = workbook.add_format(:color => 'black',:size => 10)
	  worksheet = workbook.add_worksheet

    worksheet.write(0,0,name.gsub('_',' ') + ' Report',format_title)
    worksheet.write(1,0,dfrom + '  to  ' + dto,format_title)
    
    row = 4
    headers.each_with_index do |header,column|
      worksheet.write(row - 1,column,header,format_header)
    end
    
    report_data.each_pair do |first_data,second_datas|
      if first_data == 'N/A'
        worksheet.write(row,0,first_data,format_data)
      else
        worksheet.write(row,0,retrieve_result(first_data),format_data)
      end
      
      round_of_second_datas = 1
      second_datas.each_pair do |second_data,third_datas|
        row += 1 if round_of_second_datas > 1
        worksheet.write(row,1,retrieve_result(second_data),format_data)
        round_of_third_datas = 1
        third_datas.each_pair do |third_data,forth_datas|
          row += 1 if round_of_third_datas > 1
          worksheet.write(row,2,retrieve_result(third_data),format_data)
          if headers.size > 4
            round_of_forth_datas = 1
            forth_datas.each_pair do |forth_data,fifth_datas|
              row += 1 if round_of_forth_datas > 1
              worksheet.write(row,3,retrieve_result(forth_data),format_data)
              if headers.size > 5
                round_of_fifth_datas = 1
                fifth_datas.each_pair do |fifth_data,sixth_data|
                  row += 1 if round_of_fifth_datas > 1
                  worksheet.write(row,4,retrieve_result(fifth_data),format_data)
                  worksheet.write(row,5,sixth_data,format_data)
                  round_of_fifth_datas += 1
                end
              else
                worksheet.write(row,4,fifth_datas,format_data)
              end
              round_of_forth_datas +=1
            end
          else
            worksheet.write(row,3,forth_datas,format_data)
          end
          round_of_third_datas += 1
        end
        round_of_second_datas += 1
      end
      worksheet.write(row+1,headers.size - 2,'Total',format_data)
      worksheet.write(row+1,headers.size - 1,report_total[first_data],format_data)
      row += 2
    end
    worksheet.write(row,headers.size - 2,'Grand Total',format_data)
    worksheet.write(row,headers.size - 1,report_gtotal,format_data)
    workbook.close
    send_file(file_path, :disposition => 'attachment', :encoding => 'utf8', :type => 'application/octet-stream')
  end
  def export_grand_total_billcount(name,headers,report_data,report_total,report_gtotal,dfrom, dto)
    time = Time.now.strftime('%Y%m%d%H%M%S')
	  file_name = "#{name}_#{time}".gsub(' ','_')
	  file_path = "#{RAILS_ROOT}/public/ReportFile/#{file_name}.xls"
	  workbook  = Spreadsheet::WriteExcel.new(file_path);
	  format_title = workbook.add_format(:bold => 1,:color => 'black', :size => 14,:merge => 5)
	  format_header = workbook.add_format(:bold => 1,:color => 'black', :bg_color => 27 ,:size => 12,:merge => 1,:align => 'vcenter')
	  format_data = workbook.add_format(:color => 'black',:size => 10)
	  worksheet = workbook.add_worksheet

    worksheet.write(0,2,name.gsub('_',' ') + ' Report',format_title)
    worksheet.write(1,2,dfrom + '  to  ' + dto,format_title)

    row = 4
    headers.each_with_index do |header,column|
      worksheet.write(row - 1,column,header,format_header)
    end

    report_data.each_pair do |first_data,second_datas|
      worksheet.write(row,0,retrieve_result(first_data),format_data)
      second_datas.each_pair do |second_data,third_datas|
        worksheet.write(row,1,retrieve_result(second_data),format_data)
        worksheet.write(row,2,third_datas['Quotation'],format_data)
        worksheet.write(row,3,third_datas['P/O'],format_data)
        worksheet.write(row,4,third_datas['Invoice'],format_data)
        row += 1
      end
      worksheet.write(row,1,'Total',format_data)
      worksheet.write(row,2,report_total[first_data]['Quotation'],format_data)
      worksheet.write(row,3,report_total[first_data]['P/O'],format_data)
      worksheet.write(row,4,report_total[first_data]['Invoice'],format_data)
      row += 1
    end
    worksheet.write(row,1,'Grand Total',format_data)
    worksheet.write(row,2,report_gtotal['Quotation'],format_data)
    worksheet.write(row,3,report_gtotal['P/O'],format_data)
    worksheet.write(row,4,report_gtotal['Invoice'],format_data)
    workbook.close
    send_file(file_path, :disposition => 'attachment', :encoding => 'utf8', :type => 'application/octet-stream')
  end
  # ====== Action Daily Report with Export ======
  def action_daily
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/
  end

  def action_daily_report
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/
  end
  
  def action_daily_type1_5(date_from, date_to)
    #Product Type -> Sales Office -> Salesman -> Potential Rank -> Customer
    @date_from = date_from
    @date_to = date_to
    screen_all = get_all_screen
    cf_all = get_all_customfield
    #Branch
    branch_screen = screen_all['sales office']

    #Staff
    sales_screen = screen_all['staff']

    #Potential Rank
    rank_screen = screen_all['potential rank']

    #Action
    action_screen = screen_all['action_revision']

    #Task
    task_screen = screen_all['task_detail']

    #Business Record
    business_screen = screen_all['business record']

    #Product Type
    product_screen = screen_all['product_type']

    #Customer
    customer_screen = screen_all['customer']


    cf_branch = cf_all['sales_office_ref']
    cf_product_type = cf_all['production_type_ref']
    cf_customer = cf_all['customer_ref']
    cf_issue_tracking = cf_all['issue tracking']
    cf_action_type = cf_all['action type']
    cf_visit_purpose = cf_all['visit purpose']
    cf_task_purpose = cf_all['task purpose']
    cf_salesman = cf_all['salesman_ref']
    cf_quotation_date = cf_all['quotation date']
    cf_po_date = cf_all['po date']
    cf_invoice_date = cf_all['invoice date']
    cf_delivery_date = cf_all['delivery date']
    cf_payment_date = cf_all['payment date']
    cf_quotation_amount = cf_all['quotation amount']
    cf_po_amount = cf_all['po amount']
    cf_invoice_amount = cf_all['invoice amount']
    cf_delivery_amount = cf_all['delivery amount']
    cf_payment_amount = cf_all['payment amount']
    cf_login = cf_all['login']
    cf_rank = cf_all['potential_rank_ref']

    action_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id,cf_action_type.id,cf_visit_purpose.id]
    task_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_task_purpose.id]
    business_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_quotation_date.id,  cf_po_date.id, cf_invoice_date.id, cf_delivery_date.id, cf_payment_date.id, cf_quotation_amount.id, cf_po_amount.id,  cf_invoice_amount.id, cf_delivery_amount.id, cf_payment_amount.id]

    @result = {} #Keep amount of all activity
    @total = {} #Keep total amount of all activity
    @total['action'] ||={}
    @total['task'] ||={}
    @total['business'] ||={}

    all_ref = gen_ref_values([product_screen.id,branch_screen.id,sales_screen.id,rank_screen.id,customer_screen.id], [])
    custrank_ref = gen_ref_values(customer_screen.id, cf_rank.id)

    product_screen.rows.each do |p|
      product_type = all_ref[p.id]
      @result[product_type] ||={}
      @total[product_type] ||={}
      @total[product_type]['action'] ||={}
      @total[product_type]['task'] ||={}
      @total[product_type]['business'] ||={}

      branch_screen.rows.each do |b|
        b_descr = b.description
        @result[product_type][b_descr] ||={}
        @total[product_type][b_descr] ||={}
        @total[product_type][b_descr]['action'] ||={}
        @total[product_type][b_descr]['task'] ||={}
        @total[product_type][b_descr]['business'] ||={}

        sales_rows = Row.find(:all,
          :joins => [:cells],
          :conditions => ['cells.value like ? and cells.field_id = ? and rows.screen_id = ?', "%#{b.id.to_s}%", cf_branch.id , sales_screen.id])
        sales_rows = sales_rows.select{|r| r if CustomFields::Reference.cell_ref_row_id(r.cell(cf_branch.id).value) == b.id}.compact
        row_ids = []
        sales_rows.each {|s| row_ids << s.id}
        sales_rows = Row.find(:all,
          :joins => [:cells],
          :conditions => ['cells.value != '' and cells.field_id = ? and rows.screen_id = ? and rows.id in (?)', cf_login.id.to_s, sales_screen.id, row_ids])
        sales_rows.each do |fs|
          sales_name = all_ref[fs.id]
          @result[product_type][b_descr][sales_name] ||={}

          @total[product_type][b_descr][sales_name] ||={}
          @total[product_type][b_descr][sales_name]['action'] ||={}
          @total[product_type][b_descr][sales_name]['task'] ||={}
          @total[product_type][b_descr][sales_name]['business'] ||={}

          # ----- Potential Rank ------
          rank_screen.rows.each do |r|
            rank_name = all_ref[r.id]
            @result[product_type][b_descr][sales_name][rank_name] ||={}
            @total[product_type][b_descr][sales_name][rank_name] ||={}
            @total[product_type][b_descr][sales_name][rank_name]['action'] ||={}
            @total[product_type][b_descr][sales_name][rank_name]['task'] ||={}
            @total[product_type][b_descr][sales_name][rank_name]['business'] ||={}
          end # End of Potential Rank
        end # End of sales_rows.each
      end # End @branch_screen.rows.each
    end # End of Product Type Screen

    # ------ Action ------
    action_rows = get_action_rows(action_screen.id, cf_issue_tracking.id, @date_from, @date_to)[0]

    a_rows = gen_rows_by_fields(action_rows, action_field_ids)

    action_rows.each do |fa|
      next if (customer_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_customer.id])) == 0
      next if (salesman_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_salesman.id])) == 0
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_product_type.id])) == 0

      ptype = all_ref[product_type_id]
      branch = company_branch_hash(salesman_id, all_ref, screen_all['staff'], cf_all['sales_office_ref'])
      salesman = all_ref[salesman_id]

      next if @result[ptype][branch].nil? || @result[ptype][branch][salesman].nil?

      action_type_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_action_type.id])
      customer_rank = custrank_ref[customer_id]
      customer_name = all_ref[customer_id]

      if action_type_id == 0
        action_type_name = 'Other'
      else
        action_type_name = Label.find(action_type_id).caption.name
      end

      if action_type_name == 'Visit'
        visit_purpose_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_visit_purpose.id])
        if visit_purpose_id == 0
          action_type_name = 'Routine'
        else
          action_type_name = Label.find(visit_purpose_id).caption.name
        end
      end

      if @result[ptype][branch][salesman][customer_rank].nil?
        @result[ptype][branch][salesman][customer_rank] ||={}
        @result[ptype][branch][salesman][customer_rank][customer_name] ||={}
        @result[ptype][branch][salesman][customer_rank][customer_name]['action'] ||={}
        @result[ptype][branch][salesman][customer_rank][customer_name]['task'] ||={}
        @result[ptype][branch][salesman][customer_rank][customer_name]['business'] ||={}
        @total[ptype][branch][salesman][customer_rank] ||={}
        @total[ptype][branch][salesman][customer_rank]['action'] ||={}
        @total[ptype][branch][salesman][customer_rank]['task'] ||={}
        @total[ptype][branch][salesman][customer_rank]['business'] ||={}
      end

      if @result[ptype][branch][salesman][customer_rank][customer_name].nil?
        @result[ptype][branch][salesman][customer_rank][customer_name] ||={}
        @result[ptype][branch][salesman][customer_rank][customer_name]['action'] ||={}
        @result[ptype][branch][salesman][customer_rank][customer_name]['task'] ||={}
        @result[ptype][branch][salesman][customer_rank][customer_name]['business'] ||={}
      end

      increase_summarized_value(@result, @total, [ptype,branch,salesman,customer_rank,customer_name], :action, action_type_name)

      # ------ Task ------
      task_rows =  fa.detail_rows

      t_rows = gen_rows_by_fields(task_rows, task_field_ids)
      task_rows.each do |ft|
        task_purpose_id = CustomFields::RadioButton.cell_label_id(t_rows[ft.id][cf_task_purpose.id])
        if task_purpose_id == 0
          action_type_name = 'Other'
        else
          action_type_name = Label.find(task_purpose_id).caption.name
        end
        
        increase_summarized_value(@result, @total, [ptype, branch, salesman, customer_rank, customer_name], :task, action_type_name)
      end
    end # End of @action_screen.rows.each
    # ------ Business Record ------
    row_ids = []
    sql_head = 'SELECT rows.* FROM rows INNER JOIN cells on rows.id = cells.row_id WHERE (rows.screen_id = ' + business_screen.id.to_s + ' AND (cells.field_id = '
    sql_last = " and cells.value between '" + @date_from + "' and '" + @date_to + "'))"
    sql = sql_head + cf_quotation_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_po_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_invoice_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_delivery_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_payment_date.id.to_s + sql_last

    business_rows = Row.find_by_sql(sql)
    brows = gen_rows_by_fields(business_rows, business_field_ids)

    business_rows.each do |fb|

      issue = brows[fb.id][cf_issue_tracking.id]

      next if (customer_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_customer.id])) == 0
      next if (salesman_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_salesman.id])) == 0
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_product_type.id])) == 0

      ptype = all_ref[product_type_id]
      branch = company_branch_hash(salesman_id, all_ref, screen_all['staff'], cf_all['sales_office_ref'])
      salesman = all_ref[salesman_id]

      next if @result[ptype][branch].nil? || @result[ptype][branch][salesman].nil?

      customer_rank = custrank_ref[customer_id]
      customer_name = all_ref[customer_id]

      br_date = []
      br_amount = []
      br_name = ['Quotation','P/O','Delivery','Invoice','Payment']
      br_count = ['Quotation_count','P/O_count','Delivery_count','Invoice_count','Payment_count']

      br_date << brows[fb.id][cf_quotation_date.id]
      br_date << brows[fb.id][cf_po_date.id]
      br_date << brows[fb.id][cf_delivery_date.id]
      br_date << brows[fb.id][cf_invoice_date.id]
      br_date << brows[fb.id][cf_payment_date.id]

      br_amount << brows[fb.id][cf_quotation_amount.id]
      br_amount << brows[fb.id][cf_po_amount.id]
      br_amount << brows[fb.id][cf_delivery_amount.id]
      br_amount << brows[fb.id][cf_invoice_amount.id]
      br_amount << brows[fb.id][cf_payment_amount.id]

      if @result[ptype][branch][salesman][customer_rank].nil?
        @result[ptype][branch][salesman][customer_rank] ||={}
        @result[ptype][branch][salesman][customer_rank][customer_name] ||={}
        @result[ptype][branch][salesman][customer_rank][customer_name]['action'] ||={}
        @result[ptype][branch][salesman][customer_rank][customer_name]['task'] ||={}
        @result[ptype][branch][salesman][customer_rank][customer_name]['business'] ||={}
        @total[ptype][branch][salesman][customer_rank] ||={}
        @total[ptype][branch][salesman][customer_rank]['action'] ||={}
        @total[ptype][branch][salesman][customer_rank]['task'] ||={}
        @total[ptype][branch][salesman][customer_rank]['business'] ||={}
      end

      if @result[ptype][branch][salesman][customer_rank][customer_name].nil?
        @result[ptype][branch][salesman][customer_rank][customer_name] ||={}
        @result[ptype][branch][salesman][customer_rank][customer_name]['action'] ||={}
        @result[ptype][branch][salesman][customer_rank][customer_name]['task'] ||={}
        @result[ptype][branch][salesman][customer_rank][customer_name]['business'] ||={}
      end

      i = 0
      for i in 0..br_name.size-1
        next if ((br_name[i] != 'Quotation') && CustomFields::IssueTracking.issue_state(issue) == :cancelled)
        if ((br_date[i] >= @date_from) && (br_date[i] <= @date_to))
          increase_summarized_value(@result, @total, [ptype,branch,salesman,customer_rank,customer_name], :business, br_name[i], br_amount[i].to_f, 0.0)
          increase_summarized_value(@result, @total, [ptype,branch,salesman,customer_rank,customer_name], :business, br_count[i])
        end
      end
    end # End of business record
    return @result, @total
  end
  def action_daily_type1_4(date_from, date_to)
    #Product Type -> Sales Office -> Salesman -> Potential Rank
    @date_from = date_from
    @date_to = date_to
    screen_all = get_all_screen
    cf_all = get_all_customfield
    #Branch
    branch_screen = screen_all['sales office']

    #Staff
    sales_screen = screen_all['staff']

    #Potential Rank
    rank_screen = screen_all['potential rank']

    #Action
    action_screen = screen_all['action_revision']

    #Task
    task_screen = screen_all['task_detail']

    #Business Record
    business_screen = screen_all['business record']

    #Product Type
    product_screen = screen_all['product_type']

    #Customer
    customer_screen = screen_all['customer']

    cf_branch = cf_all['sales_office_ref']
    cf_product_type = cf_all['production_type_ref']
    cf_customer = cf_all['customer_ref']
    cf_issue_tracking = cf_all['issue tracking']
    cf_action_type = cf_all['action type']
    cf_visit_purpose = cf_all['visit purpose']
    cf_task_purpose = cf_all['task purpose']
    cf_salesman = cf_all['salesman_ref']
    cf_quotation_date = cf_all['quotation date']
    cf_po_date = cf_all['po date']
    cf_invoice_date = cf_all['invoice date']
    cf_delivery_date = cf_all['delivery date']
    cf_payment_date = cf_all['payment date']
    cf_quotation_amount = cf_all['quotation amount']
    cf_po_amount = cf_all['po amount']
    cf_invoice_amount = cf_all['invoice amount']
    cf_delivery_amount = cf_all['delivery amount']
    cf_payment_amount = cf_all['payment amount']
    cf_login = cf_all['login']
    cf_rank = cf_all['potential_rank_ref']

    action_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id,cf_action_type.id,cf_visit_purpose.id]
    task_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_task_purpose.id]
    business_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_quotation_date.id,  cf_po_date.id, cf_invoice_date.id, cf_delivery_date.id, cf_payment_date.id, cf_quotation_amount.id, cf_po_amount.id,  cf_invoice_amount.id, cf_delivery_amount.id, cf_payment_amount.id]

    @result = {} #Keep amount of all activity
    @total = {} #Keep total amount of all activity
    @total['action'] ||={}
    @total['task'] ||={}
    @total['business'] ||={}

    all_ref = gen_ref_values([product_screen.id,branch_screen.id,sales_screen.id,rank_screen.id], [])
    custrank_ref = gen_ref_values(customer_screen.id, cf_rank.id)

    product_screen.rows.each do |p|
      product_type = all_ref[p.id]
      @result[product_type] ||={}
      @total[product_type] ||={}
      @total[product_type]['action'] ||={}
      @total[product_type]['task'] ||={}
      @total[product_type]['business'] ||={}

      branch_screen.rows.each do |b|
        b_descr = b.description
        @result[product_type][b_descr] ||={}
        @total[product_type][b_descr] ||={}
        @total[product_type][b_descr]['action'] ||={}
        @total[product_type][b_descr]['task'] ||={}
        @total[product_type][b_descr]['business'] ||={}

        sales_rows = Row.find(:all,
          :joins => [:cells],
          :conditions => ['cells.value like ? and cells.field_id = ? and rows.screen_id = ?', "%#{b.id.to_s}%", cf_branch.id , sales_screen.id])
        sales_rows = sales_rows.select{|r| r if CustomFields::Reference.cell_ref_row_id(r.cell(cf_branch.id).value) == b.id}.compact
        row_ids = []
        sales_rows.each {|s| row_ids << s.id}
        sales_rows = Row.find(:all,
          :joins => [:cells],
          :conditions => ['cells.value != '' and cells.field_id = ? and rows.screen_id = ? and rows.id in (?)', cf_login.id.to_s, sales_screen.id, row_ids])
        sales_rows.each do |fs|
          sales_name = all_ref[fs.id]
          @result[product_type][b_descr][sales_name] ||={}

          @total[product_type][b_descr][sales_name] ||={}
          @total[product_type][b_descr][sales_name]['action'] ||={}
          @total[product_type][b_descr][sales_name]['task'] ||={}
          @total[product_type][b_descr][sales_name]['business'] ||={}

          # ----- Potential Rank ------
          rank_screen.rows.each do |r|
            rank_name = all_ref[r.id]
            @result[product_type][b_descr][sales_name][rank_name] ||={}
            @result[product_type][b_descr][sales_name][rank_name]['action'] ||={}
            @result[product_type][b_descr][sales_name][rank_name]['task'] ||={}
            @result[product_type][b_descr][sales_name][rank_name]['business'] ||={}
            @total[product_type][b_descr][sales_name][rank_name] ||={}
            @total[product_type][b_descr][sales_name][rank_name]['action'] ||={}
            @total[product_type][b_descr][sales_name][rank_name]['task'] ||={}
            @total[product_type][b_descr][sales_name][rank_name]['business'] ||={}
          end # End of Potential Rank
        end # End of sales_rows.each
      end # End @branch_screen.rows.each
    end # End of Product Type Screen

    # ------ Action ------
    action_rows = get_action_rows(action_screen.id, cf_issue_tracking.id, @date_from, @date_to)[0]

    a_rows = gen_rows_by_fields(action_rows, action_field_ids)
    
    action_rows.each do |fa|
      next if (customer_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_customer.id])) == 0
      next if (salesman_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_salesman.id])) == 0
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_product_type.id])) == 0

      ptype = all_ref[product_type_id]
      branch = company_branch_hash(salesman_id, all_ref, screen_all['staff'], cf_all['sales_office_ref'])
      salesman = all_ref[salesman_id]

      next if @result[ptype][branch].nil? || @result[ptype][branch][salesman].nil?

      action_type_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_action_type.id])
      customer_rank = custrank_ref[customer_id]
      if action_type_id == 0
        action_type_name = 'Other'
      else
        action_type_name = Label.find(action_type_id).caption.name
      end

      if action_type_name == 'Visit'
        visit_purpose_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_visit_purpose.id])
        if visit_purpose_id == 0
          action_type_name = 'Routine'
        else
          action_type_name = Label.find(visit_purpose_id).caption.name
        end
      end

      if @result[ptype][branch][salesman][customer_rank].nil?
        @result[ptype][branch][salesman][customer_rank] ||={}
        @result[ptype][branch][salesman][customer_rank]['action'] ||={}
        @result[ptype][branch][salesman][customer_rank]['task'] ||={}
        @result[ptype][branch][salesman][customer_rank]['business'] ||={}
      end

      increase_summarized_value(@result, @total, [ptype,branch,salesman,customer_rank], :action, action_type_name)

      # ------ Task ------
      task_rows =  fa.detail_rows

      t_rows = gen_rows_by_fields(task_rows, task_field_ids)
      task_rows.each do |ft|
        task_purpose_id = CustomFields::RadioButton.cell_label_id(t_rows[ft.id][cf_task_purpose.id])
        if task_purpose_id == 0
          action_type_name = 'Other'
        else
          action_type_name = Label.find(task_purpose_id).caption.name
        end
        customer_rank = custrank_ref[customer_id]

        increase_summarized_value(@result, @total, [ptype,branch,salesman,customer_rank], :task, action_type_name)
      end
    end # End of @action_screen.rows.each
    # ------ Business Record ------
    row_ids = []
    sql_head = 'SELECT rows.* FROM rows INNER JOIN cells on rows.id = cells.row_id WHERE (rows.screen_id = ' + business_screen.id.to_s + ' AND (cells.field_id = '
    sql_last = " and cells.value between '" + @date_from + "' and '" + @date_to + "'))"
    sql = sql_head + cf_quotation_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_po_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_invoice_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_delivery_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_payment_date.id.to_s + sql_last
    business_rows = Row.find_by_sql(sql)
    brows = gen_rows_by_fields(business_rows, business_field_ids)
    business_rows.each do |fb|
      issue = brows[fb.id][cf_issue_tracking.id]

      next if (customer_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_customer.id])) == 0
      next if (salesman_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_salesman.id])) == 0
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_product_type.id])) == 0

      ptype = all_ref[product_type_id]
      branch = company_branch_hash(salesman_id, all_ref, screen_all['staff'], cf_all['sales_office_ref'])
      salesman = all_ref[salesman_id]

      next if @result[ptype][branch].nil? || @result[ptype][branch][salesman].nil?

      customer_rank = custrank_ref[customer_id]

      br_date = []
      br_amount = []
      br_name = ['Quotation','P/O','Delivery','Invoice','Payment']
      br_count = ['Quotation_count','P/O_count','Delivery_count','Invoice_count','Payment_count']

      br_date << brows[fb.id][cf_quotation_date.id]
      br_date << brows[fb.id][cf_po_date.id]
      br_date << brows[fb.id][cf_delivery_date.id]
      br_date << brows[fb.id][cf_invoice_date.id]
      br_date << brows[fb.id][cf_payment_date.id]

      br_amount << brows[fb.id][cf_quotation_amount.id]
      br_amount << brows[fb.id][cf_po_amount.id]
      br_amount << brows[fb.id][cf_delivery_amount.id]
      br_amount << brows[fb.id][cf_invoice_amount.id]
      br_amount << brows[fb.id][cf_payment_amount.id]

      if @result[ptype][branch][salesman][customer_rank].nil?
        @result[ptype][branch][salesman][customer_rank] ||={}
        @result[ptype][branch][salesman][customer_rank]['action'] ||={}
        @result[ptype][branch][salesman][customer_rank]['task'] ||={}
        @result[ptype][branch][salesman][customer_rank]['business'] ||={}
      end

      i = 0
      for i in 0..br_name.size-1
        next if ((br_name[i] != 'Quotation') && CustomFields::IssueTracking.issue_state(issue) == :cancelled)
        if ((br_date[i] >= @date_from) && (br_date[i] <= @date_to))
          increase_summarized_value(@result, @total, [ptype,branch,salesman,customer_rank], :business, br_name[i], br_amount[i].to_f, 0.0)
          increase_summarized_value(@result, @total, [ptype,branch,salesman,customer_rank], :business, br_count[i])
        end
      end
    end # End of business record
    return @result, @total
  end
  def action_daily_type1_3(date_from, date_to)
    #Product Type -> Sales Office -> Salesman
    @date_from = date_from
    @date_to = date_to
    screen_all = get_all_screen
    cf_all = get_all_customfield
    #Branch
    branch_screen = screen_all['sales office']

    #Staff
    sales_screen = screen_all['staff']

    #Action
    action_screen = screen_all['action_revision']

    #Task
    task_screen = screen_all['task_detail']

    #Business Record
    business_screen = screen_all['business record']

    #Product Type
    product_screen = screen_all['product_type']

    cf_branch = cf_all['sales_office_ref']
    cf_product_type = cf_all['production_type_ref']
    cf_customer = cf_all['customer_ref']
    cf_issue_tracking = cf_all['issue tracking']
    cf_action_type = cf_all['action type']
    cf_visit_purpose = cf_all['visit purpose']
    cf_task_purpose = cf_all['task purpose']
    cf_salesman = cf_all['salesman_ref']
    cf_quotation_date = cf_all['quotation date']
    cf_po_date = cf_all['po date']
    cf_invoice_date = cf_all['invoice date']
    cf_delivery_date = cf_all['delivery date']
    cf_payment_date = cf_all['payment date']
    cf_quotation_amount = cf_all['quotation amount']
    cf_po_amount = cf_all['po amount']
    cf_invoice_amount = cf_all['invoice amount']
    cf_delivery_amount = cf_all['delivery amount']
    cf_payment_amount = cf_all['payment amount']
    cf_login = cf_all['login']

    action_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id,cf_action_type.id,cf_visit_purpose.id]
    task_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_task_purpose.id]
    business_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_quotation_date.id,  cf_po_date.id, cf_invoice_date.id, cf_delivery_date.id, cf_payment_date.id, cf_quotation_amount.id, cf_po_amount.id,  cf_invoice_amount.id, cf_delivery_amount.id, cf_payment_amount.id]

    @result = {} #Keep amount of all activity
    @total = {} #Keep total amount of all activity
    @total['action'] ||={}
    @total['task'] ||={}
    @total['business'] ||={}

    all_ref = gen_ref_values([product_screen.id,branch_screen.id,sales_screen.id], [])

    product_screen.rows.each do |p|
      product_type = all_ref[p.id]
      @result[product_type] ||={}
      @total[product_type] ||={}
      @total[product_type]['action'] ||={}
      @total[product_type]['task'] ||={}
      @total[product_type]['business'] ||={}

      branch_screen.rows.each do |b|
        b_descr = b.description
        @result[product_type][b_descr] ||={}
        @total[product_type][b_descr] ||={}
        @total[product_type][b_descr]['action'] ||={}
        @total[product_type][b_descr]['task'] ||={}
        @total[product_type][b_descr]['business'] ||={}

        sales_rows = Row.find(:all,
          :joins => [:cells],
          :conditions => ['cells.value like ? and cells.field_id = ? and rows.screen_id = ?', "%#{b.id.to_s}%", cf_branch.id , sales_screen.id])
        sales_rows = sales_rows.select{|r| r if CustomFields::Reference.cell_ref_row_id(r.cell(cf_branch.id).value) == b.id}.compact
        row_ids = []
        sales_rows.each {|s| row_ids << s.id}
        sales_rows = Row.find(:all,
          :joins => [:cells],
          :conditions => ['cells.value != '' and cells.field_id = ? and rows.screen_id = ? and rows.id in (?)', cf_login.id.to_s, sales_screen.id, row_ids])
        sales_rows.each do |fs|
          sales_name = all_ref[fs.id]
          @result[product_type][b_descr][sales_name] ||={}
          @result[product_type][b_descr][sales_name]['action'] ||={}
          @result[product_type][b_descr][sales_name]['task'] ||={}
          @result[product_type][b_descr][sales_name]['business'] ||={}
          @total[product_type][b_descr][sales_name] ||={}
          @total[product_type][b_descr][sales_name]['action'] ||={}
          @total[product_type][b_descr][sales_name]['task'] ||={}
          @total[product_type][b_descr][sales_name]['business'] ||={}

        end # End of sales_rows.each
      end # End @branch_screen.rows.each
    end # End of Product Type Screen

    # ------ Action ------
    action_rows = get_action_rows(action_screen.id, cf_issue_tracking.id, @date_from, @date_to)[0]

    a_rows = gen_rows_by_fields(action_rows, action_field_ids)

    action_rows.each do |fa|
      next if (salesman_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_salesman.id])) == 0
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_product_type.id])) == 0

      ptype = all_ref[product_type_id]
      branch = company_branch_hash(salesman_id, all_ref, screen_all['staff'], cf_all['sales_office_ref'])
      salesman = all_ref[salesman_id]

      next if @result[ptype][branch].nil? || @result[ptype][branch][salesman].nil?

      action_type_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_action_type.id])
      if action_type_id == 0
        action_type_name = 'Other'
      else
        action_type_name = Label.find(action_type_id).caption.name
      end

      if action_type_name == 'Visit'
        visit_purpose_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_visit_purpose.id])
        if visit_purpose_id == 0
          action_type_name = 'Routine'
        else
          action_type_name = Label.find(visit_purpose_id).caption.name
        end
      end
        
      increase_summarized_value(@result, @total, [ptype,branch,salesman], :action, action_type_name)

      # ------ Task ------
      task_rows =  fa.detail_rows

      t_rows = gen_rows_by_fields(task_rows, task_field_ids)
      task_rows.each do |ft|
        task_purpose_id = CustomFields::RadioButton.cell_label_id(t_rows[ft.id][cf_task_purpose.id])
        if task_purpose_id == 0
          action_type_name = 'Other'
        else
          action_type_name = Label.find(task_purpose_id).caption.name
        end

        increase_summarized_value(@result, @total, [ptype,branch,salesman], :task, action_type_name)
      end
    end # End of @action_screen.rows.each
    # ------ Business Record ------
    row_ids = []
    sql_head = 'SELECT rows.* FROM rows INNER JOIN cells on rows.id = cells.row_id WHERE (rows.screen_id = ' + business_screen.id.to_s + ' AND (cells.field_id = '
    sql_last = " and cells.value between '" + @date_from + "' and '" + @date_to + "'))"
    sql = sql_head + cf_quotation_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_po_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_invoice_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_delivery_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_payment_date.id.to_s + sql_last

    business_rows = Row.find_by_sql(sql)
    brows = gen_rows_by_fields(business_rows, business_field_ids)
    business_rows.each do |fb|
      issue = brows[fb.id][cf_issue_tracking.id]

      next if (salesman_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_salesman.id])) == 0
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_product_type.id])) == 0

      ptype = all_ref[product_type_id]
      branch = company_branch_hash(salesman_id, all_ref, screen_all['staff'], cf_all['sales_office_ref'])
      salesman = all_ref[salesman_id]

      next if @result[ptype][branch].nil? || @result[ptype][branch][salesman].nil?

      br_date = []
      br_amount = []
      br_name = ['Quotation','P/O','Delivery','Invoice','Payment']
      br_count = ['Quotation_count','P/O_count','Delivery_count','Invoice_count','Payment_count']

      br_date << brows[fb.id][cf_quotation_date.id]
      br_date << brows[fb.id][cf_po_date.id]
      br_date << brows[fb.id][cf_delivery_date.id]
      br_date << brows[fb.id][cf_invoice_date.id]
      br_date << brows[fb.id][cf_payment_date.id]

      br_amount << brows[fb.id][cf_quotation_amount.id]
      br_amount << brows[fb.id][cf_po_amount.id]
      br_amount << brows[fb.id][cf_delivery_amount.id]
      br_amount << brows[fb.id][cf_invoice_amount.id]
      br_amount << brows[fb.id][cf_payment_amount.id]

      i = 0
      for i in 0..br_name.size-1
        next if ((br_name[i] != 'Quotation') && CustomFields::IssueTracking.issue_state(issue) == :cancelled)
        if ((br_date[i] >= @date_from) && (br_date[i] <= @date_to))
          increase_summarized_value(@result, @total, [ptype,branch,salesman], :business, br_name[i], br_amount[i].to_f, 0.0)
          increase_summarized_value(@result, @total, [ptype,branch,salesman], :business, br_count[i])
        end
      end
    end # End of business record
    return @result, @total
  end
  def action_daily_type1_2(date_from, date_to)
    #Product Type -> Sales Office
    @date_from = date_from
    @date_to = date_to
    screen_all = get_all_screen
    cf_all = get_all_customfield
    #Branch
    branch_screen = screen_all['sales office']

    #Action
    action_screen = screen_all['action_revision']

    #Task
    task_screen = screen_all['task_detail']

    #Business Record
    business_screen = screen_all['business record']

    #Product Type
    product_screen = screen_all['product_type']

    cf_product_type = cf_all['production_type_ref']
    cf_customer = cf_all['customer_ref']
    cf_issue_tracking = cf_all['issue tracking']
    cf_action_type = cf_all['action type']
    cf_visit_purpose = cf_all['visit purpose']
    cf_task_purpose = cf_all['task purpose']
    cf_salesman = cf_all['salesman_ref']
    cf_quotation_date = cf_all['quotation date']
    cf_po_date = cf_all['po date']
    cf_invoice_date = cf_all['invoice date']
    cf_delivery_date = cf_all['delivery date']
    cf_payment_date = cf_all['payment date']
    cf_quotation_amount = cf_all['quotation amount']
    cf_po_amount = cf_all['po amount']
    cf_invoice_amount = cf_all['invoice amount']
    cf_delivery_amount = cf_all['delivery amount']
    cf_payment_amount = cf_all['payment amount']

    action_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id,cf_action_type.id,cf_visit_purpose.id]
    task_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_task_purpose.id]
    business_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_quotation_date.id,  cf_po_date.id, cf_invoice_date.id, cf_delivery_date.id, cf_payment_date.id, cf_quotation_amount.id, cf_po_amount.id,  cf_invoice_amount.id, cf_delivery_amount.id, cf_payment_amount.id]

    @result = {} #Keep amount of all activity
    @total = {} #Keep total amount of all activity
    @total['action'] ||={}
    @total['task'] ||={}
    @total['business'] ||={}

    all_ref = gen_ref_values([product_screen.id,branch_screen.id], [])

    product_screen.rows.each do |p|
      product_type = all_ref[p.id]
      @result[product_type] ||={}
      @total[product_type] ||={}
      @total[product_type]['action'] ||={}
      @total[product_type]['task'] ||={}
      @total[product_type]['business'] ||={}

      branch_screen.rows.each do |b|
        b_descr = b.description
        @result[product_type][b_descr] ||={}
        @result[product_type][b_descr]['action'] ||={}
        @result[product_type][b_descr]['task'] ||={}
        @result[product_type][b_descr]['business'] ||={}
        @total[product_type][b_descr] ||={}
        @total[product_type][b_descr]['action'] ||={}
        @total[product_type][b_descr]['task'] ||={}
        @total[product_type][b_descr]['business'] ||={}

      end # End @branch_screen.rows.each
    end # End of Product Type Screen

    # ------ Action ------
    action_rows = get_action_rows(action_screen.id, cf_issue_tracking.id, @date_from, @date_to)[0]

    a_rows = gen_rows_by_fields(action_rows, action_field_ids)

    action_rows.each do |fa|
      next if (salesman_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_salesman.id])) == 0
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_product_type.id])) == 0

      ptype = all_ref[product_type_id]
      branch = company_branch_hash(salesman_id, all_ref, screen_all['staff'], cf_all['sales_office_ref'])

      action_type_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_action_type.id])

      if action_type_id == 0
        action_type_name = 'Other'
      else
        action_type_name = Label.find(action_type_id).caption.name
      end

      if action_type_name == 'Visit'
        visit_purpose_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_visit_purpose.id])
        if visit_purpose_id == 0
          action_type_name = 'Routine'
        else
          action_type_name = Label.find(visit_purpose_id).caption.name
        end
      end

      increase_summarized_value(@result, @total, [ptype,branch], :action, action_type_name)

      # ------ Task ------
      task_rows = fa.detail_rows

      t_rows = gen_rows_by_fields(task_rows, task_field_ids)
      task_rows.each do |ft|
        task_purpose_id = CustomFields::RadioButton.cell_label_id(t_rows[ft.id][cf_task_purpose.id])

        if task_purpose_id == 0
          action_type_name = 'Other'
        else
          action_type_name = Label.find(task_purpose_id).caption.name
        end

        increase_summarized_value(@result, @total, [ptype,branch], :task, action_type_name)
      end
    end # End of @action_screen.rows.each
    # ------ Business Record ------
    row_ids = []
    sql_head = 'SELECT rows.* FROM rows INNER JOIN cells on rows.id = cells.row_id WHERE (rows.screen_id = ' + business_screen.id.to_s + ' AND (cells.field_id = '
    sql_last = " and cells.value between '" + @date_from + "' and '" + @date_to + "'))"
    sql = sql_head + cf_quotation_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_po_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_invoice_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_delivery_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_payment_date.id.to_s + sql_last

    business_rows = Row.find_by_sql(sql)
    brows = gen_rows_by_fields(business_rows, business_field_ids)
    business_rows.each do |fb|
      issue = brows[fb.id][cf_issue_tracking.id]

      next if (salesman_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_salesman.id])) == 0
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_product_type.id])) == 0

      ptype = all_ref[product_type_id]
      branch = company_branch_hash(salesman_id, all_ref, screen_all['staff'], cf_all['sales_office_ref'])

      br_date = []
      br_amount = []
      br_name = ['Quotation','P/O','Delivery','Invoice','Payment']
      br_count = ['Quotation_count','P/O_count','Delivery_count','Invoice_count','Payment_count']

      br_date << brows[fb.id][cf_quotation_date.id]
      br_date << brows[fb.id][cf_po_date.id]
      br_date << brows[fb.id][cf_delivery_date.id]
      br_date << brows[fb.id][cf_invoice_date.id]
      br_date << brows[fb.id][cf_payment_date.id]

      br_amount << brows[fb.id][cf_quotation_amount.id]
      br_amount << brows[fb.id][cf_po_amount.id]
      br_amount << brows[fb.id][cf_delivery_amount.id]
      br_amount << brows[fb.id][cf_invoice_amount.id]
      br_amount << brows[fb.id][cf_payment_amount.id]

      i = 0
      for i in 0..br_name.size-1
        next if ((br_name[i] != 'Quotation') && CustomFields::IssueTracking.issue_state(issue) == :cancelled)
        if ((br_date[i] >= @date_from) && (br_date[i] <= @date_to))
          increase_summarized_value(@result, @total, [ptype,branch], :business, br_name[i], br_amount[i].to_f, 0.0)
          increase_summarized_value(@result, @total, [ptype,branch], :business, br_count[i])
        end
      end
    end # End of business record
    return @result, @total
  end
  def action_daily_type1_1(date_from, date_to)
    #Product Type
    @date_from = date_from
    @date_to = date_to
    screen_all = get_all_screen
    cf_all = get_all_customfield
    #Action
    action_screen = screen_all['action_revision']

    #Task
    task_screen = screen_all['task_detail']

    #Business Record
    business_screen = screen_all['business record']

    #Product Type
    product_screen = screen_all['product_type']

    cf_product_type = cf_all['production_type_ref']
    cf_customer = cf_all['customer_ref']
    cf_issue_tracking = cf_all['issue tracking']
    cf_action_type = cf_all['action type']
    cf_visit_purpose = cf_all['visit purpose']
    cf_task_purpose = cf_all['task purpose']
    cf_salesman = cf_all['salesman_ref']
    cf_quotation_date = cf_all['quotation date']
    cf_po_date = cf_all['po date']
    cf_invoice_date = cf_all['invoice date']
    cf_delivery_date = cf_all['delivery date']
    cf_payment_date = cf_all['payment date']
    cf_quotation_amount = cf_all['quotation amount']
    cf_po_amount = cf_all['po amount']
    cf_invoice_amount = cf_all['invoice amount']
    cf_delivery_amount = cf_all['delivery amount']
    cf_payment_amount = cf_all['payment amount']

    action_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id,cf_action_type.id,cf_visit_purpose.id]
    task_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_task_purpose.id]
    business_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_quotation_date.id,  cf_po_date.id, cf_invoice_date.id, cf_delivery_date.id, cf_payment_date.id, cf_quotation_amount.id, cf_po_amount.id,  cf_invoice_amount.id, cf_delivery_amount.id, cf_payment_amount.id]

    @result = {} #Keep amount of all activity
    @total = {} #Keep total amount of all activity
    @total['action'] ||={}
    @total['task'] ||={}
    @total['business'] ||={}

    ptype_ref = gen_ref_values(product_screen.id)
    
    product_screen.rows.each do |p|
      product_type = ptype_ref[p.id]
      @result[product_type] ||={}
      @result[product_type]['action'] ||={}
      @result[product_type]['task'] ||={}
      @result[product_type]['business'] ||={}
      @total[product_type] ||={}
      @total[product_type]['action'] ||={}
      @total[product_type]['task'] ||={}
      @total[product_type]['business'] ||={}

    end # End of Product Type Screen

    # ------ Action ------
    action_rows = get_action_rows(action_screen.id, cf_issue_tracking.id, @date_from, @date_to)[0]

    a_rows = gen_rows_by_fields(action_rows, action_field_ids)

    action_rows.each do |fa|
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_product_type.id])) == 0

      ptype = ptype_ref[product_type_id]

      action_type_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_action_type.id])

      if action_type_id == 0
        action_type_name = 'Other'
      else
        action_type_name = Label.find(action_type_id).caption.name
      end

      if action_type_name == 'Visit'
        visit_purpose_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_visit_purpose.id])
        if visit_purpose_id == 0
          action_type_name = 'Routine'
        else
          action_type_name = Label.find(visit_purpose_id).caption.name
        end
      end

      increase_summarized_value(@result, @total, [ptype], :action, action_type_name)

      # ------ Task ------
      task_rows = fa.detail_rows

      t_rows = gen_rows_by_fields(task_rows, task_field_ids)
      task_rows.each do |ft|
        task_purpose_id = CustomFields::RadioButton.cell_label_id(t_rows[ft.id][cf_task_purpose.id])

        if task_purpose_id == 0
          action_type_name = 'Other'
        else
          action_type_name = Label.find(task_purpose_id).caption.name
        end
        
        increase_summarized_value(@result, @total, [ptype], :task, action_type_name)
      end
    end # End of @action_screen.rows.each
    # ------ Business Record ------
    row_ids = []
    sql_head = 'SELECT rows.* FROM rows INNER JOIN cells on rows.id = cells.row_id WHERE (rows.screen_id = ' + business_screen.id.to_s + ' AND (cells.field_id = '
    sql_last = " and cells.value between '" + @date_from + "' and '" + @date_to + "'))"
    sql = sql_head + cf_quotation_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_po_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_invoice_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_delivery_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_payment_date.id.to_s + sql_last

    business_rows = Row.find_by_sql(sql)
    brows = gen_rows_by_fields(business_rows, business_field_ids)
    business_rows.each do |fb|
      issue = brows[fb.id][cf_issue_tracking.id]

      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_product_type.id])) == 0

      ptype = ptype_ref[product_type_id]

      br_date = []
      br_amount = []
      br_name = ['Quotation','P/O','Delivery','Invoice','Payment']
      br_count = ['Quotation_count','P/O_count','Delivery_count','Invoice_count','Payment_count']

      br_date << brows[fb.id][cf_quotation_date.id]
      br_date << brows[fb.id][cf_po_date.id]
      br_date << brows[fb.id][cf_delivery_date.id]
      br_date << brows[fb.id][cf_invoice_date.id]
      br_date << brows[fb.id][cf_payment_date.id]

      br_amount << brows[fb.id][cf_quotation_amount.id]
      br_amount << brows[fb.id][cf_po_amount.id]
      br_amount << brows[fb.id][cf_delivery_amount.id]
      br_amount << brows[fb.id][cf_invoice_amount.id]
      br_amount << brows[fb.id][cf_payment_amount.id]

      i = 0
      for i in 0..br_name.size-1
        next if ((br_name[i] != 'Quotation') && CustomFields::IssueTracking.issue_state(issue) == :cancelled)
        if ((br_date[i] >= @date_from) && (br_date[i] <= @date_to))
          increase_summarized_value(@result, @total, [ptype], :business, br_name[i], br_amount[i].to_f, 0.0)
          increase_summarized_value(@result, @total, [ptype], :business, br_count[i])
        end
      end
    end # End of business record
    return @result, @total
  end

  def action_daily_type2_5(date_from, date_to)
    #Product Type -> Sales Office -> Salesman -> Potential Rank -> Customer
    @date_from = date_from
    @date_to = date_to
    screen_all = get_all_screen
    cf_all = get_all_customfield
    #Branch
    branch_screen = screen_all['sales office']

    #Staff
    sales_screen = screen_all['staff']

    #Action
    action_screen = screen_all['action_revision']

    #Task
    task_screen = screen_all['task_detail']

    #Business Record
    business_screen = screen_all['business record']

    #Product Type
    product_screen = screen_all['product_type']

    #Customer
    customer_screen = screen_all['customer']

    cf_branch = cf_all['sales_office_ref']
    cf_product_type = cf_all['production_type_ref']
    cf_customer = cf_all['customer_ref']
    cf_issue_tracking = cf_all['issue tracking']
    cf_action_type = cf_all['action type']
    cf_visit_purpose = cf_all['visit purpose']
    cf_task_purpose = cf_all['task purpose']
    cf_salesman = cf_all['salesman_ref']
    cf_quotation_date = cf_all['quotation date']
    cf_po_date = cf_all['po date']
    cf_invoice_date = cf_all['invoice date']
    cf_delivery_date = cf_all['delivery date']
    cf_payment_date = cf_all['payment date']
    cf_quotation_amount = cf_all['quotation amount']
    cf_po_amount = cf_all['po amount']
    cf_invoice_amount = cf_all['invoice amount']
    cf_delivery_amount = cf_all['delivery amount']
    cf_payment_amount = cf_all['payment amount']
    cf_login = cf_all['login']
    cf_firstpo = cf_all['first p/o']

    action_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id,cf_action_type.id,cf_visit_purpose.id]
    task_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_task_purpose.id]
    business_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_quotation_date.id,  cf_po_date.id, cf_invoice_date.id, cf_delivery_date.id, cf_payment_date.id, cf_quotation_amount.id, cf_po_amount.id,  cf_invoice_amount.id, cf_delivery_amount.id, cf_payment_amount.id]

    @result = {} #Keep amount of all activity
    @total = {} #Keep total amount of all activity
    @total['action'] ||={}
    @total['task'] ||={}
    @total['business'] ||={}

    all_ref = gen_ref_values([product_screen.id,branch_screen.id,sales_screen.id,customer_screen.id], [])
    custnew_ref = gen_ref_values(customer_screen.id, cf_firstpo.id)

    product_screen.rows.each do |p|
      product_type = all_ref[p.id]
      @result[product_type] ||={}
      @total[product_type] ||={}
      @total[product_type]['action'] ||={}
      @total[product_type]['task'] ||={}
      @total[product_type]['business'] ||={}

      branch_screen.rows.each do |b|
        b_descr = b.description
        @result[product_type][b_descr] ||={}
        @total[product_type][b_descr] ||={}
        @total[product_type][b_descr]['action'] ||={}
        @total[product_type][b_descr]['task'] ||={}
        @total[product_type][b_descr]['business'] ||={}

        sales_rows = Row.find(:all,
          :joins => [:cells],
          :conditions => ['cells.value like ? and cells.field_id = ? and rows.screen_id = ?', "%#{b.id.to_s}%", cf_branch.id , sales_screen.id])
        sales_rows = sales_rows.select{|r| r if CustomFields::Reference.cell_ref_row_id(r.cell(cf_branch.id).value) == b.id}.compact
        row_ids = []
        sales_rows.each {|s| row_ids << s.id}
        sales_rows = Row.find(:all,
          :joins => [:cells],
          :conditions => ['cells.value != '' and cells.field_id = ? and rows.screen_id = ? and rows.id in (?)', cf_login.id.to_s, sales_screen.id, row_ids])
        sales_rows.each do |fs|
          sales_name = all_ref[fs.id]
          @result[product_type][b_descr][sales_name] ||={}

          @total[product_type][b_descr][sales_name] ||={}
          @total[product_type][b_descr][sales_name]['action'] ||={}
          @total[product_type][b_descr][sales_name]['task'] ||={}
          @total[product_type][b_descr][sales_name]['business'] ||={}

          # ----- Type New/Existing ------
          @result[product_type][b_descr][sales_name]['Existing'] ||={}
          @total[product_type][b_descr][sales_name]['Existing'] ||={}
          @total[product_type][b_descr][sales_name]['Existing']['action'] ||={}
          @total[product_type][b_descr][sales_name]['Existing']['task'] ||={}
          @total[product_type][b_descr][sales_name]['Existing']['business'] ||={}

          @result[product_type][b_descr][sales_name]['New'] ||={}
          @total[product_type][b_descr][sales_name]['New'] ||={}
          @total[product_type][b_descr][sales_name]['New']['action'] ||={}
          @total[product_type][b_descr][sales_name]['New']['task'] ||={}
          @total[product_type][b_descr][sales_name]['New']['business'] ||={}        end # End of sales_rows.each
      end # End @branch_screen.rows.each
    end # End of Product Type Screen

    # ------ Action ------
    action_rows = get_action_rows(action_screen.id, cf_issue_tracking.id, @date_from, @date_to)[0]

    a_rows = gen_rows_by_fields(action_rows, action_field_ids)

    action_rows.each do |fa|
      next if (customer_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_customer.id])) == 0
      next if (salesman_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_salesman.id])) == 0
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_product_type.id])) == 0

      ptype = all_ref[product_type_id]
      branch = company_branch_hash(salesman_id, all_ref, screen_all['staff'], cf_all['sales_office_ref'])
      salesman = all_ref[salesman_id]

      next if @result[ptype][branch].nil? || @result[ptype][branch][salesman].nil?

      action_type_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_action_type.id])
      firstpo = custnew_ref[customer_id] || ''
      customer_rank = cust_new(firstpo, @date_from)
      customer_name = all_ref[customer_id]

      if action_type_id == 0
        action_type_name = 'Other'
      else
        action_type_name = Label.find(action_type_id).caption.name
      end

      if action_type_name == 'Visit'
        visit_purpose_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_visit_purpose.id])
        if visit_purpose_id == 0
          action_type_name = 'Routine'
        else
          action_type_name = Label.find(visit_purpose_id).caption.name
        end
      end

      if @result[ptype][branch][salesman][customer_rank][customer_name].nil?
        @result[ptype][branch][salesman][customer_rank][customer_name] ||={}
        @result[ptype][branch][salesman][customer_rank][customer_name]['action'] ||={}
        @result[ptype][branch][salesman][customer_rank][customer_name]['task'] ||={}
        @result[ptype][branch][salesman][customer_rank][customer_name]['business'] ||={}
      end

      increase_summarized_value(@result, @total, [ptype,branch,salesman,customer_rank,customer_name], :action, action_type_name)

      # ------ Task ------
      task_rows = fa.detail_rows

      t_rows = gen_rows_by_fields(task_rows, task_field_ids)
      task_rows.each do |ft|
        task_purpose_id = CustomFields::RadioButton.cell_label_id(t_rows[ft.id][cf_task_purpose.id])
        if task_purpose_id == 0
          action_type_name = 'Other'
        else
          action_type_name = Label.find(task_purpose_id).caption.name
        end

        increase_summarized_value(@result, @total, [ptype,branch,salesman,customer_rank,customer_name], :task, action_type_name)
      end
    end # End of @action_screen.rows.each
    # ------ Business Record ------
    row_ids = []
    sql_head = 'SELECT rows.* FROM rows INNER JOIN cells on rows.id = cells.row_id WHERE (rows.screen_id = ' + business_screen.id.to_s + ' AND (cells.field_id = '
    sql_last = " and cells.value between '" + @date_from + "' and '" + @date_to + "'))"
    sql = sql_head + cf_quotation_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_po_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_invoice_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_delivery_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_payment_date.id.to_s + sql_last

    business_rows = Row.find_by_sql(sql)
    brows = gen_rows_by_fields(business_rows, business_field_ids)
    business_rows.each do |fb|
      issue = brows[fb.id][cf_issue_tracking.id]

      next if (customer_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_customer.id])) == 0
      next if (salesman_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_salesman.id])) == 0
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_product_type.id])) == 0
      
      ptype = all_ref[product_type_id]
      branch = company_branch_hash(salesman_id, all_ref, screen_all['staff'], cf_all['sales_office_ref'])
      salesman = all_ref[salesman_id]

      next if @result[ptype][branch].nil? || @result[ptype][branch][salesman].nil?

      firstpo = custnew_ref[customer_id] || ''
      customer_rank = cust_new(firstpo, @date_from)
      customer_name = all_ref[customer_id]

      br_date = []
      br_amount = []
      br_name = ['Quotation','P/O','Delivery','Invoice','Payment']
      br_count = ['Quotation_count','P/O_count','Delivery_count','Invoice_count','Payment_count']

      br_date << brows[fb.id][cf_quotation_date.id]
      br_date << brows[fb.id][cf_po_date.id]
      br_date << brows[fb.id][cf_delivery_date.id]
      br_date << brows[fb.id][cf_invoice_date.id]
      br_date << brows[fb.id][cf_payment_date.id]

      br_amount << brows[fb.id][cf_quotation_amount.id]
      br_amount << brows[fb.id][cf_po_amount.id]
      br_amount << brows[fb.id][cf_delivery_amount.id]
      br_amount << brows[fb.id][cf_invoice_amount.id]
      br_amount << brows[fb.id][cf_payment_amount.id]

      if @result[ptype][branch][salesman][customer_rank][customer_name].nil?
        @result[ptype][branch][salesman][customer_rank][customer_name] ||={}
        @result[ptype][branch][salesman][customer_rank][customer_name]['action'] ||={}
        @result[ptype][branch][salesman][customer_rank][customer_name]['task'] ||={}
        @result[ptype][branch][salesman][customer_rank][customer_name]['business'] ||={}
      end

      i = 0
      for i in 0..br_name.size-1
        next if ((br_name[i] != 'Quotation') && CustomFields::IssueTracking.issue_state(issue) == :cancelled)
        if ((br_date[i] >= @date_from) && (br_date[i] <= @date_to))
          increase_summarized_value(@result, @total, [ptype,branch,salesman,customer_rank,customer_name], :business, br_name[i], br_amount[i].to_f, 0.0)
          increase_summarized_value(@result, @total, [ptype,branch,salesman,customer_rank,customer_name], :business, br_count[i])
        end
      end
    end # End of business record
    return @result, @total
  end
  def action_daily_type2_4(date_from, date_to)
    #Product Type -> Sales Office -> Salesman -> Potential Rank
    @date_from = date_from
    @date_to = date_to
    screen_all = get_all_screen
    cf_all = get_all_customfield
    #Branch
    branch_screen = screen_all['sales office']

    #Staff
    sales_screen = screen_all['staff']

    #Action
    action_screen = screen_all['action_revision']

    #Task
    task_screen = screen_all['task_detail']

    #Business Record
    business_screen = screen_all['business record']

    #Product Type
    product_screen = screen_all['product_type']
    
    #Customer
    customer_screen = screen_all['customer']

    cf_branch = cf_all['sales_office_ref']
    cf_product_type = cf_all['production_type_ref']
    cf_customer = cf_all['customer_ref']
    cf_issue_tracking = cf_all['issue tracking']
    cf_action_type = cf_all['action type']
    cf_visit_purpose = cf_all['visit purpose']
    cf_task_purpose = cf_all['task purpose']
    cf_salesman = cf_all['salesman_ref']
    cf_quotation_date = cf_all['quotation date']
    cf_po_date = cf_all['po date']
    cf_invoice_date = cf_all['invoice date']
    cf_delivery_date = cf_all['delivery date']
    cf_payment_date = cf_all['payment date']
    cf_quotation_amount = cf_all['quotation amount']
    cf_po_amount = cf_all['po amount']
    cf_invoice_amount = cf_all['invoice amount']
    cf_delivery_amount = cf_all['delivery amount']
    cf_payment_amount = cf_all['payment amount']
    cf_login = cf_all['login']
    cf_firstpo = cf_all['first p/o']

    action_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id,cf_action_type.id,cf_visit_purpose.id]
    task_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_task_purpose.id]
    business_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_quotation_date.id,  cf_po_date.id, cf_invoice_date.id, cf_delivery_date.id, cf_payment_date.id, cf_quotation_amount.id, cf_po_amount.id,  cf_invoice_amount.id, cf_delivery_amount.id, cf_payment_amount.id]

    @result = {} #Keep amount of all activity
    @total = {} #Keep total amount of all activity
    @total['action'] ||={}
    @total['task'] ||={}
    @total['business'] ||={}

    all_ref = gen_ref_values([product_screen.id,branch_screen.id,sales_screen.id], [])
    custnew_ref = gen_ref_values(customer_screen.id, cf_firstpo.id)

    product_screen.rows.each do |p|
      product_type = all_ref[p.id]
      @result[product_type] ||={}
      @total[product_type] ||={}
      @total[product_type]['action'] ||={}
      @total[product_type]['task'] ||={}
      @total[product_type]['business'] ||={}

      branch_screen.rows.each do |b|
        b_descr = b.description
        @result[product_type][b_descr] ||={}
        @total[product_type][b_descr] ||={}
        @total[product_type][b_descr]['action'] ||={}
        @total[product_type][b_descr]['task'] ||={}
        @total[product_type][b_descr]['business'] ||={}

        sales_rows = Row.find(:all,
          :joins => [:cells],
          :conditions => ['cells.value like ? and cells.field_id = ? and rows.screen_id = ?', "%#{b.id.to_s}%", cf_branch.id , sales_screen.id])
        sales_rows = sales_rows.select{|r| r if CustomFields::Reference.cell_ref_row_id(r.cell(cf_branch.id).value) == b.id}.compact
        row_ids = []
        sales_rows.each {|s| row_ids << s.id}
        sales_rows = Row.find(:all,
          :joins => [:cells],
          :conditions => ['cells.value != '' and cells.field_id = ? and rows.screen_id = ? and rows.id in (?)', cf_login.id.to_s, sales_screen.id, row_ids])
        sales_rows.each do |fs|
          sales_name = all_ref[fs.id]
          @result[product_type][b_descr][sales_name] ||={}

          @total[product_type][b_descr][sales_name] ||={}
          @total[product_type][b_descr][sales_name]['action'] ||={}
          @total[product_type][b_descr][sales_name]['task'] ||={}
          @total[product_type][b_descr][sales_name]['business'] ||={}

          # ----- Type New/Existing ------
          @result[product_type][b_descr][sales_name]['Existing'] ||={}
          @result[product_type][b_descr][sales_name]['Existing']['action'] ||={}
          @result[product_type][b_descr][sales_name]['Existing']['task'] ||={}
          @result[product_type][b_descr][sales_name]['Existing']['business'] ||={}
          @total[product_type][b_descr][sales_name]['Existing'] ||={}
          @total[product_type][b_descr][sales_name]['Existing']['action'] ||={}
          @total[product_type][b_descr][sales_name]['Existing']['task'] ||={}
          @total[product_type][b_descr][sales_name]['Existing']['business'] ||={}

          @result[product_type][b_descr][sales_name]['New'] ||={}
          @result[product_type][b_descr][sales_name]['New']['action'] ||={}
          @result[product_type][b_descr][sales_name]['New']['task'] ||={}
          @result[product_type][b_descr][sales_name]['New']['business'] ||={}
          @total[product_type][b_descr][sales_name]['New'] ||={}
          @total[product_type][b_descr][sales_name]['New']['action'] ||={}
          @total[product_type][b_descr][sales_name]['New']['task'] ||={}
          @total[product_type][b_descr][sales_name]['New']['business'] ||={}

        end # End of sales_rows.each
      end # End @branch_screen.rows.each
    end # End of Product Type Screen

    # ------ Action ------
    action_rows = get_action_rows(action_screen.id, cf_issue_tracking.id, @date_from, @date_to)[0]

    a_rows = gen_rows_by_fields(action_rows, action_field_ids)

    action_rows.each do |fa|
      next if (customer_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_customer.id])) == 0
      next if (salesman_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_salesman.id])) == 0
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_product_type.id])) == 0

      ptype = all_ref[product_type_id]
      branch = company_branch_hash(salesman_id, all_ref, screen_all['staff'], cf_all['sales_office_ref'])
      salesman = all_ref[salesman_id]

      next if @result[ptype][branch].nil? || @result[ptype][branch][salesman].nil?

      action_type_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_action_type.id])
      firstpo = custnew_ref[customer_id] || ''
      customer_rank = cust_new(firstpo, @date_from)

      if action_type_id == 0
        action_type_name = 'Other'
      else
        action_type_name = Label.find(action_type_id).caption.name
      end

      if action_type_name == 'Visit'
        visit_purpose_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_visit_purpose.id])
        if visit_purpose_id == 0
          action_type_name = 'Routine'
        else
          action_type_name = Label.find(visit_purpose_id).caption.name
        end
      end

      increase_summarized_value(@result, @total, [ptype,branch,salesman,customer_rank], :action, action_type_name)
      
      # ------ Task ------
      task_rows = fa.detail_rows

      t_rows = gen_rows_by_fields(task_rows, task_field_ids)
      task_rows.each do |ft|
        task_purpose_id = CustomFields::RadioButton.cell_label_id(t_rows[ft.id][cf_task_purpose.id])
        if task_purpose_id == 0
          action_type_name = 'Other'
        else
          action_type_name = Label.find(task_purpose_id).caption.name
        end

        increase_summarized_value(@result, @total, [ptype,branch,salesman,customer_rank], :task, action_type_name)
      end
    end # End of @action_screen.rows.each
    # ------ Business Record ------
    row_ids = []
    sql_head = 'SELECT rows.* FROM rows INNER JOIN cells on rows.id = cells.row_id WHERE (rows.screen_id = ' + business_screen.id.to_s + ' AND (cells.field_id = '
    sql_last = " and cells.value between '" + @date_from + "' and '" + @date_to + "'))"
    sql = sql_head + cf_quotation_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_po_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_invoice_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_delivery_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_payment_date.id.to_s + sql_last

    business_rows = Row.find_by_sql(sql)
    brows = gen_rows_by_fields(business_rows, business_field_ids)
    business_rows.each do |fb|
      issue = brows[fb.id][cf_issue_tracking.id]

      next if (customer_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_customer.id])) == 0
      next if (salesman_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_salesman.id])) == 0
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_product_type.id])) == 0
      
      ptype = all_ref[product_type_id]
      branch = company_branch_hash(salesman_id, all_ref, screen_all['staff'], cf_all['sales_office_ref'])
      salesman = all_ref[salesman_id]

      next if @result[ptype][branch].nil? || @result[ptype][branch][salesman].nil?

      firstpo = custnew_ref[customer_id] || ''
      customer_rank = cust_new(firstpo, @date_from)

      br_date = []
      br_amount = []
      br_name = ['Quotation','P/O','Delivery','Invoice','Payment']
      br_count = ['Quotation_count','P/O_count','Delivery_count','Invoice_count','Payment_count']

      br_date << brows[fb.id][cf_quotation_date.id]
      br_date << brows[fb.id][cf_po_date.id]
      br_date << brows[fb.id][cf_delivery_date.id]
      br_date << brows[fb.id][cf_invoice_date.id]
      br_date << brows[fb.id][cf_payment_date.id]

      br_amount << brows[fb.id][cf_quotation_amount.id]
      br_amount << brows[fb.id][cf_po_amount.id]
      br_amount << brows[fb.id][cf_delivery_amount.id]
      br_amount << brows[fb.id][cf_invoice_amount.id]
      br_amount << brows[fb.id][cf_payment_amount.id]

      i = 0
      for i in 0..br_name.size-1
        next if ((br_name[i] != 'Quotation') && CustomFields::IssueTracking.issue_state(issue) == :cancelled)
        if ((br_date[i] >= @date_from) && (br_date[i] <= @date_to))
          increase_summarized_value(@result, @total, [ptype,branch,salesman,customer_rank], :business, br_name[i], br_amount[i].to_f, 0.0)
          increase_summarized_value(@result, @total, [ptype,branch,salesman,customer_rank], :business, br_count[i])
        end
      end
    end # End of business record
    return @result, @total
  end

  def action_daily_rank_1(date_from, date_to)
    #Potential Rank -> Customer -> Product Type
    @date_from = date_from
    @date_to = date_to
    screen_all = get_all_screen
    cf_all = get_all_customfield

    #Potential Rank
    rank_screen = screen_all['potential rank']

    #Action
    action_screen = screen_all['action_revision']

    #Task
    task_screen = screen_all['task_detail']

    #Business Record
    business_screen = screen_all['business record']

    #Product Type
    product_screen = screen_all['product_type']

    #Customer
    customer_screen = screen_all['customer']

    cf_product_type = cf_all['production_type_ref']
    cf_customer = cf_all['customer_ref']
    cf_issue_tracking = cf_all['issue tracking']
    cf_action_type = cf_all['action type']
    cf_visit_purpose = cf_all['visit purpose']
    cf_task_purpose = cf_all['task purpose']
    cf_salesman = cf_all['salesman_ref']
    cf_quotation_date = cf_all['quotation date']
    cf_po_date = cf_all['po date']
    cf_invoice_date = cf_all['invoice date']
    cf_delivery_date = cf_all['delivery date']
    cf_payment_date = cf_all['payment date']
    cf_quotation_amount = cf_all['quotation amount']
    cf_po_amount = cf_all['po amount']
    cf_invoice_amount = cf_all['invoice amount']
    cf_delivery_amount = cf_all['delivery amount']
    cf_payment_amount = cf_all['payment amount']
    cf_rank = cf_all['potential_rank_ref']

    action_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id,cf_action_type.id,cf_visit_purpose.id]
    task_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_task_purpose.id]
    business_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_quotation_date.id,  cf_po_date.id, cf_invoice_date.id, cf_delivery_date.id, cf_payment_date.id, cf_quotation_amount.id, cf_po_amount.id,  cf_invoice_amount.id, cf_delivery_amount.id, cf_payment_amount.id]

    @result = {} #Keep amount of all activity
    @total = {} #Keep total amount of all activity
    @total['action'] ||={}
    @total['task'] ||={}
    @total['business'] ||={}

    all_ref = gen_ref_values([product_screen.id,rank_screen.id,customer_screen.id], [])
    custrank_ref = gen_ref_values(customer_screen.id, cf_rank.id)

    rank_screen.rows.each do |r|
      rank_name = all_ref[r.id]
      @result[rank_name] ||={}
      @total[rank_name] ||={}
      @total[rank_name]['action'] ||={}
      @total[rank_name]['task'] ||={}
      @total[rank_name]['business'] ||={}
    end # End of Potential Rank

    # ------ Action ------
    action_rows = get_action_rows(action_screen.id, cf_issue_tracking.id, @date_from, @date_to)[0]

    a_rows = gen_rows_by_fields(action_rows, action_field_ids)

    action_rows.each do |fa|
      next if (customer_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_customer.id])) == 0
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_product_type.id])) == 0

      ptype = all_ref[product_type_id]

      action_type_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_action_type.id])
      customer_rank = custrank_ref[customer_id]
      customer_name = all_ref[customer_id]

      if action_type_id == 0
        action_type_name = 'Other'
      else
        action_type_name = Label.find(action_type_id).caption.name
      end

      if action_type_name == 'Visit'
        visit_purpose_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_visit_purpose.id])
        if visit_purpose_id == 0
          action_type_name = 'Routine'
        else
          action_type_name = Label.find(visit_purpose_id).caption.name
        end
      end

      if @result[customer_rank].nil?
        @result[customer_rank] ||={}
        @total[customer_rank] ||={}
        @total[customer_rank]['action'] ||={}
        @total[customer_rank]['task'] ||={}
        @total[customer_rank]['business'] ||={}
      end
      if @result[customer_rank][customer_name].nil?
        @result[customer_rank][customer_name] ||={}
        @total[customer_rank][customer_name] ||={}
        @total[customer_rank][customer_name]['action'] ||={}
        @total[customer_rank][customer_name]['task'] ||={}
        @total[customer_rank][customer_name]['business'] ||={}
      end
      if @result[customer_rank][customer_name][ptype].nil?
        product_screen.rows.each do |p|
          ptype = ptype = all_ref[p.id]
          @result[customer_rank][customer_name][ptype] ||={}
          @result[customer_rank][customer_name][ptype]['action'] ||={}
          @result[customer_rank][customer_name][ptype]['task'] ||={}
          @result[customer_rank][customer_name][ptype]['business'] ||={}
        end # End of Product Type Screen
      end

      increase_summarized_value(@result, @total, [customer_rank,customer_name,ptype], :action, action_type_name)

      # ------ Task ------
      task_rows = fa.detail_rows

      t_rows = gen_rows_by_fields(task_rows, task_field_ids)
      task_rows.each do |ft|
        task_purpose_id = CustomFields::RadioButton.cell_label_id(t_rows[ft.id][cf_task_purpose.id])

        if task_purpose_id == 0
          action_type_name = 'Other'
        else
          action_type_name = Label.find(task_purpose_id).caption.name
        end

        increase_summarized_value(@result, @total, [customer_rank,customer_name,ptype], :task, action_type_name)
      end
    end # End of @action_screen.rows.each
    # ------ Business Record ------
    row_ids = []
    sql_head = 'SELECT rows.* FROM rows INNER JOIN cells on rows.id = cells.row_id WHERE (rows.screen_id = ' + business_screen.id.to_s + ' AND (cells.field_id = '
    sql_last = " and cells.value between '" + @date_from + "' and '" + @date_to + "'))"
    sql = sql_head + cf_quotation_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_po_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_invoice_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_delivery_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_payment_date.id.to_s + sql_last

    business_rows = Row.find_by_sql(sql)
    brows = gen_rows_by_fields(business_rows, business_field_ids)
    business_rows.each do |fb|
      issue = brows[fb.id][cf_issue_tracking.id]

      next if (customer_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_customer.id])) == 0
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_product_type.id])) == 0

      ptype = all_ref[product_type_id]

      customer_rank = custrank_ref[customer_id]
      customer_name = all_ref[customer_id]

      br_date = []
      br_amount = []
      br_name = ['Quotation','P/O','Delivery','Invoice','Payment']
      br_count = ['Quotation_count','P/O_count','Delivery_count','Invoice_count','Payment_count']

      br_date << brows[fb.id][cf_quotation_date.id]
      br_date << brows[fb.id][cf_po_date.id]
      br_date << brows[fb.id][cf_delivery_date.id]
      br_date << brows[fb.id][cf_invoice_date.id]
      br_date << brows[fb.id][cf_payment_date.id]

      br_amount << brows[fb.id][cf_quotation_amount.id]
      br_amount << brows[fb.id][cf_po_amount.id]
      br_amount << brows[fb.id][cf_delivery_amount.id]
      br_amount << brows[fb.id][cf_invoice_amount.id]
      br_amount << brows[fb.id][cf_payment_amount.id]

      if @result[customer_rank].nil?
        @result[customer_rank] ||={}
        @total[customer_rank] ||={}
        @total[customer_rank]['action'] ||={}
        @total[customer_rank]['task'] ||={}
        @total[customer_rank]['business'] ||={}
      end
      if @result[customer_rank][customer_name].nil?
        @result[customer_rank][customer_name] ||={}
        @total[customer_rank][customer_name] ||={}
        @total[customer_rank][customer_name]['action'] ||={}
        @total[customer_rank][customer_name]['task'] ||={}
        @total[customer_rank][customer_name]['business'] ||={}
      end
      if @result[customer_rank][customer_name][ptype].nil?
        product_screen.rows.each do |p|
          ptype = ptype = all_ref[p.id]
          @result[customer_rank][customer_name][ptype] ||={}
          @result[customer_rank][customer_name][ptype]['action'] ||={}
          @result[customer_rank][customer_name][ptype]['task'] ||={}
          @result[customer_rank][customer_name][ptype]['business'] ||={}
        end # End of Product Type Screen
      end

      i = 0
      for i in 0..br_name.size-1
        next if ((br_name[i] != 'Quotation') && CustomFields::IssueTracking.issue_state(issue) == :cancelled)
        if ((br_date[i] >= @date_from) && (br_date[i] <= @date_to))
          increase_summarized_value(@result, @total, [customer_rank,customer_name,ptype], :business, br_name[i], br_amount[i].to_f, 0.0)
          increase_summarized_value(@result, @total, [customer_rank,customer_name,ptype], :business, br_count[i])
        end
      end
    end # End of business record
    return @result, @total
  end

  def action_daily_rank_2(date_from, date_to)
    #Potential Rank -> Product Type -> Customer
    @date_from = date_from
    @date_to = date_to
    screen_all = get_all_screen
    cf_all = get_all_customfield
    #Potential Rank
    rank_screen = screen_all['potential rank']

    #Action
    action_screen = screen_all['action_revision']

    #Task
    task_screen = screen_all['task_detail']

    #Business Record
    business_screen = screen_all['business record']

    #Product Type
    product_screen = screen_all['product_type']

    #Customer
    customer_screen = screen_all['customer']

    cf_product_type = cf_all['production_type_ref']
    cf_customer = cf_all['customer_ref']
    cf_issue_tracking = cf_all['issue tracking']
    cf_action_type = cf_all['action type']
    cf_visit_purpose = cf_all['visit purpose']
    cf_task_purpose = cf_all['task purpose']
    cf_salesman = cf_all['salesman_ref']
    cf_quotation_date = cf_all['quotation date']
    cf_po_date = cf_all['po date']
    cf_invoice_date = cf_all['invoice date']
    cf_delivery_date = cf_all['delivery date']
    cf_payment_date = cf_all['payment date']
    cf_quotation_amount = cf_all['quotation amount']
    cf_po_amount = cf_all['po amount']
    cf_invoice_amount = cf_all['invoice amount']
    cf_delivery_amount = cf_all['delivery amount']
    cf_payment_amount = cf_all['payment amount']
    cf_rank = cf_all['potential_rank_ref']

    action_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id,cf_action_type.id,cf_visit_purpose.id]
    task_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_task_purpose.id]
    business_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_quotation_date.id,  cf_po_date.id, cf_invoice_date.id, cf_delivery_date.id, cf_payment_date.id, cf_quotation_amount.id, cf_po_amount.id,  cf_invoice_amount.id, cf_delivery_amount.id, cf_payment_amount.id]

    @result = {} #Keep amount of all activity
    @total = {} #Keep total amount of all activity
    @total['action'] ||={}
    @total['task'] ||={}
    @total['business'] ||={}

    all_ref = gen_ref_values([product_screen.id,rank_screen.id,customer_screen.id], [])
    custrank_ref = gen_ref_values(customer_screen.id, cf_rank.id)

    rank_screen.rows.each do |r|
      rank_name = all_ref[r.id]
      @result[rank_name] ||={}
      @total[rank_name] ||={}
      @total[rank_name]['action'] ||={}
      @total[rank_name]['task'] ||={}
      @total[rank_name]['business'] ||={}

      product_screen.rows.each do |p|
        ptype = all_ref[p.id]
        @result[rank_name][ptype] ||={}
        @total[rank_name][ptype] ||={}
        @total[rank_name][ptype]['action'] ||={}
        @total[rank_name][ptype]['task'] ||={}
        @total[rank_name][ptype]['business'] ||={}
      end # End of Product Type Screen
    end # End of Potential Rank

    # ------ Action ------
    action_rows = get_action_rows(action_screen.id, cf_issue_tracking.id, @date_from, @date_to)[0]

    a_rows = gen_rows_by_fields(action_rows, action_field_ids)

    action_rows.each do |fa|
      next if (customer_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_customer.id])) == 0
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_product_type.id])) == 0

      ptype = all_ref[product_type_id]

      action_type_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_action_type.id])
      customer_rank = custrank_ref[customer_id]
      customer_name = all_ref[customer_id]

      if action_type_id == 0
        action_type_name = 'Other'
      else
        action_type_name = Label.find(action_type_id).caption.name
      end

      if action_type_name == 'Visit'
        visit_purpose_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_visit_purpose.id])
        if visit_purpose_id == 0
          action_type_name = 'Routine'
        else
          action_type_name = Label.find(visit_purpose_id).caption.name
        end
      end

      if @result[customer_rank].nil?
        @result[customer_rank] ||={}
        @total[customer_rank] ||={}
        @total[customer_rank]['action'] ||={}
        @total[customer_rank]['task'] ||={}
        @total[customer_rank]['business'] ||={}

        product_screen.rows.each do |p|
          ptype = all_ref[p.id]
          @result[customer_rank][ptype] ||={}
          @total[customer_rank][ptype] ||={}
          @total[customer_rank][ptype]['action'] ||={}
          @total[customer_rank][ptype]['task'] ||={}
          @total[customer_rank][ptype]['business'] ||={}
        end # End of Product Type Screen
      end

      if @result[customer_rank][ptype][customer_name].nil?
        @result[customer_rank][ptype][customer_name] ||={}
        @result[customer_rank][ptype][customer_name]['action'] ||={}
        @result[customer_rank][ptype][customer_name]['task'] ||={}
        @result[customer_rank][ptype][customer_name]['business'] ||={}
      end

      increase_summarized_value(@result, @total, [customer_rank,ptype,customer_name], :action, action_type_name)

      # ------ Task ------
      task_rows = fa.detail_rows

      t_rows = gen_rows_by_fields(task_rows, task_field_ids)
      task_rows.each do |ft|
        task_purpose_id = CustomFields::RadioButton.cell_label_id(t_rows[ft.id][cf_task_purpose.id])

        if task_purpose_id == 0
          action_type_name = 'Other'
        else
          action_type_name = Label.find(task_purpose_id).caption.name
        end

        increase_summarized_value(@result, @total, [customer_rank,ptype,customer_name], :task, action_type_name)
      end
    end # End of @action_screen.rows.each
    # ------ Business Record ------
    row_ids = []
    sql_head = 'SELECT rows.* FROM rows INNER JOIN cells on rows.id = cells.row_id WHERE (rows.screen_id = ' + business_screen.id.to_s + ' AND (cells.field_id = '
    sql_last = " and cells.value between '" + @date_from + "' and '" + @date_to + "'))"
    sql = sql_head + cf_quotation_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_po_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_invoice_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_delivery_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_payment_date.id.to_s + sql_last

    business_rows = Row.find_by_sql(sql)
    brows = gen_rows_by_fields(business_rows, business_field_ids)
    business_rows.each do |fb|
      issue = brows[fb.id][cf_issue_tracking.id]

      next if (customer_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_customer.id])) == 0
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_product_type.id])) == 0

      ptype = all_ref[product_type_id]

      customer_rank = custrank_ref[customer_id]
      customer_name = all_ref[customer_id]

      br_date = []
      br_amount = []
      br_name = ['Quotation','P/O','Delivery','Invoice','Payment']
      br_count = ['Quotation_count','P/O_count','Delivery_count','Invoice_count','Payment_count']

      br_date << brows[fb.id][cf_quotation_date.id]
      br_date << brows[fb.id][cf_po_date.id]
      br_date << brows[fb.id][cf_delivery_date.id]
      br_date << brows[fb.id][cf_invoice_date.id]
      br_date << brows[fb.id][cf_payment_date.id]

      br_amount << brows[fb.id][cf_quotation_amount.id]
      br_amount << brows[fb.id][cf_po_amount.id]
      br_amount << brows[fb.id][cf_delivery_amount.id]
      br_amount << brows[fb.id][cf_invoice_amount.id]
      br_amount << brows[fb.id][cf_payment_amount.id]

      if @result[customer_rank].nil?
        @result[customer_rank] ||={}
        @total[customer_rank] ||={}
        @total[customer_rank]['action'] ||={}
        @total[customer_rank]['task'] ||={}
        @total[customer_rank]['business'] ||={}

        product_screen.rows.each do |p|
          ptype = all_ref[p.id]
          @result[customer_rank][ptype] ||={}
          @total[customer_rank][ptype] ||={}
          @total[customer_rank][ptype]['action'] ||={}
          @total[customer_rank][ptype]['task'] ||={}
          @total[customer_rank][ptype]['business'] ||={}
        end # End of Product Type Screen
      end

      if @result[customer_rank][ptype][customer_name].nil?
        @result[customer_rank][ptype][customer_name] ||={}
        @result[customer_rank][ptype][customer_name]['action'] ||={}
        @result[customer_rank][ptype][customer_name]['task'] ||={}
        @result[customer_rank][ptype][customer_name]['business'] ||={}
      end

      i = 0
      for i in 0..br_name.size-1
        next if ((br_name[i] != 'Quotation') && CustomFields::IssueTracking.issue_state(issue) == :cancelled)
        if ((br_date[i] >= @date_from) && (br_date[i] <= @date_to))
          increase_summarized_value(@result, @total, [customer_rank,ptype,customer_name], :business, br_name[i], br_amount[i].to_f, 0.0)
          increase_summarized_value(@result, @total, [customer_rank,ptype,customer_name], :business, br_count[i])
        end
      end
    end # End of business record
    return @result, @total
  end

  def action_daily_rpt_1(date_from, date_to, rpt_ref)
    #Province -> Potential Rank -> Customer -> Product Type
    @date_from = date_from
    @date_to = date_to
    screen_all = get_all_screen
    cf_all = get_all_customfield
    #Potential Rank
    rank_screen = screen_all['potential rank']

    #Action
    action_screen = screen_all['action_revision']

    #Task
    task_screen = screen_all['task_detail']

    #Business Record
    business_screen = screen_all['business record']

    #Product Type
    product_screen = screen_all['product_type']

    #Customer
    customer_screen = screen_all['customer']

    #item ==> Estate_REF and Province REF
    if rpt_ref == 'Estate_REF'
      item_screen = screen_all['industrial estate']
    elsif rpt_ref == 'Province_REF'
      item_screen = screen_all['province']
    end

    cf_product_type = cf_all['production_type_ref']
    cf_customer = cf_all['customer_ref']
    cf_issue_tracking = cf_all['issue tracking']
    cf_action_type = cf_all['action type']
    cf_visit_purpose = cf_all['visit purpose']
    cf_task_purpose = cf_all['task purpose']
    cf_salesman = cf_all['salesman_ref']
    cf_quotation_date = cf_all['quotation date']
    cf_po_date = cf_all['po date']
    cf_invoice_date = cf_all['invoice date']
    cf_delivery_date = cf_all['delivery date']
    cf_payment_date = cf_all['payment date']
    cf_quotation_amount = cf_all['quotation amount']
    cf_po_amount = cf_all['po amount']
    cf_invoice_amount = cf_all['invoice amount']
    cf_delivery_amount = cf_all['delivery amount']
    cf_payment_amount = cf_all['payment amount']
    cf_rank = cf_all['potential_rank_ref']
    rpt_custom_field_id = cf_all[rpt_ref.downcase].id

    action_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id,cf_action_type.id,cf_visit_purpose.id]
    task_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_task_purpose.id]
    business_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_quotation_date.id,  cf_po_date.id, cf_invoice_date.id, cf_delivery_date.id, cf_payment_date.id, cf_quotation_amount.id, cf_po_amount.id,  cf_invoice_amount.id, cf_delivery_amount.id, cf_payment_amount.id]

    @result = {} #Keep amount of all activity
    @total = {} #Keep total amount of all activity
    @total['action'] ||={}
    @total['task'] ||={}
    @total['business'] ||={}

    all_ref = gen_ref_values([product_screen.id,rank_screen.id,customer_screen.id,item_screen.id], [])
    custrank_ref = gen_ref_values(customer_screen.id, cf_rank.id)
    rptitem_ref = gen_ref_values(customer_screen.id, rpt_custom_field_id)

    # ------ Action ------
    action_rows = get_action_rows(action_screen.id, cf_issue_tracking.id, @date_from, @date_to)[0]

    a_rows = gen_rows_by_fields(action_rows, action_field_ids)

    action_rows.each do |fa|
      next if (customer_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_customer.id])) == 0
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_product_type.id])) == 0

      item = rptitem_ref[customer_id]

      ptype = all_ref[product_type_id]

      action_type_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_action_type.id])
      customer_rank = custrank_ref[customer_id]
      customer_name = all_ref[customer_id]

      if action_type_id == 0
        action_type_name = 'Other'
      else
        action_type_name = Label.find(action_type_id).caption.name
      end

      if action_type_name == 'Visit'
        visit_purpose_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_visit_purpose.id])
        if visit_purpose_id == 0
          action_type_name = 'Routine'
        else
          action_type_name = Label.find(visit_purpose_id).caption.name
        end
      end

      if @result[item].nil?
        @result[item] ||={}
        @total[item] ||={}
        @total[item]['action'] ||={}
        @total[item]['task'] ||={}
        @total[item]['business'] ||={}

        rank_screen.rows.each do |r|
          rank_name = all_ref[r.id]
          @result[item][rank_name] ||={}
          @total[item][rank_name] ||={}
          @total[item][rank_name]['action'] ||={}
          @total[item][rank_name]['task'] ||={}
          @total[item][rank_name]['business'] ||={}
        end # End of Potential Rank
      end

      if @result[item][customer_rank].nil?
        @result[item][customer_rank] ||={}
        @total[item][customer_rank] ||={}
        @total[item][customer_rank]['action'] ||={}
        @total[item][customer_rank]['task'] ||={}
        @total[item][customer_rank]['business'] ||={}
      end
      if @result[item][customer_rank][customer_name].nil?
        @result[item][customer_rank][customer_name] ||={}
        @total[item][customer_rank][customer_name] ||={}
        @total[item][customer_rank][customer_name]['action'] ||={}
        @total[item][customer_rank][customer_name]['task'] ||={}
        @total[item][customer_rank][customer_name]['business'] ||={}
      end
      if @result[item][customer_rank][customer_name][ptype].nil?
        product_screen.rows.each do |p|
          ptype = all_ref[p.id]
          @result[item][customer_rank][customer_name][ptype] ||={}
          @result[item][customer_rank][customer_name][ptype]['action'] ||={}
          @result[item][customer_rank][customer_name][ptype]['task'] ||={}
          @result[item][customer_rank][customer_name][ptype]['business'] ||={}
        end # End of Product Type Screen
      end

      increase_summarized_value(@result, @total, [item,customer_rank,customer_name,ptype], :action, action_type_name)

      # ------ Task ------
      task_rows = fa.detail_rows

      t_rows = gen_rows_by_fields(task_rows, task_field_ids)
      task_rows.each do |ft|
        task_purpose_id = CustomFields::RadioButton.cell_label_id(t_rows[ft.id][cf_task_purpose.id])

        if task_purpose_id == 0
          action_type_name = 'Other'
        else
          action_type_name = Label.find(task_purpose_id).caption.name
        end

        increase_summarized_value(@result, @total, [item,customer_rank,customer_name,ptype], :task, action_type_name)
      end
    end # End of @action_screen.rows.each
    # ------ Business Record ------
    row_ids = []
    sql_head = 'SELECT rows.* FROM rows INNER JOIN cells on rows.id = cells.row_id WHERE (rows.screen_id = ' + business_screen.id.to_s + ' AND (cells.field_id = '
    sql_last = " and cells.value between '" + @date_from + "' and '" + @date_to + "'))"
    sql = sql_head + cf_quotation_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_po_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_invoice_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_delivery_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_payment_date.id.to_s + sql_last

    business_rows = Row.find_by_sql(sql)
    brows = gen_rows_by_fields(business_rows, business_field_ids)
    business_rows.each do |fb|
      issue = brows[fb.id][cf_issue_tracking.id]

      next if (customer_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_customer.id])) == 0
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_product_type.id])) == 0

      ptype = all_ref[product_type_id]

      item = rptitem_ref[customer_id]

      customer_rank = custrank_ref[customer_id]
      customer_name = all_ref[customer_id]

      br_date = []
      br_amount = []
      br_name = ['Quotation','P/O','Delivery','Invoice','Payment']
      br_count = ['Quotation_count','P/O_count','Delivery_count','Invoice_count','Payment_count']

      br_date << brows[fb.id][cf_quotation_date.id]
      br_date << brows[fb.id][cf_po_date.id]
      br_date << brows[fb.id][cf_delivery_date.id]
      br_date << brows[fb.id][cf_invoice_date.id]
      br_date << brows[fb.id][cf_payment_date.id]

      br_amount << brows[fb.id][cf_quotation_amount.id]
      br_amount << brows[fb.id][cf_po_amount.id]
      br_amount << brows[fb.id][cf_delivery_amount.id]
      br_amount << brows[fb.id][cf_invoice_amount.id]
      br_amount << brows[fb.id][cf_payment_amount.id]

      if @result[item].nil?
        @result[item] ||={}
        @total[item] ||={}
        @total[item]['action'] ||={}
        @total[item]['task'] ||={}
        @total[item]['business'] ||={}

        rank_screen.rows.each do |r|
          rank_name = all_ref[r.id]
          @result[item][rank_name] ||={}
          @total[item][rank_name] ||={}
          @total[item][rank_name]['action'] ||={}
          @total[item][rank_name]['task'] ||={}
          @total[item][rank_name]['business'] ||={}
        end # End of Potential Rank
      end

      if @result[item][customer_rank].nil?
        @result[item][customer_rank] ||={}
        @total[item][customer_rank] ||={}
        @total[item][customer_rank]['action'] ||={}
        @total[item][customer_rank]['task'] ||={}
        @total[item][customer_rank]['business'] ||={}
      end
      if @result[item][customer_rank][customer_name].nil?
        @result[item][customer_rank][customer_name] ||={}
        @total[item][customer_rank][customer_name] ||={}
        @total[item][customer_rank][customer_name]['action'] ||={}
        @total[item][customer_rank][customer_name]['task'] ||={}
        @total[item][customer_rank][customer_name]['business'] ||={}
      end
      if @result[item][customer_rank][customer_name][ptype].nil?
        product_screen.rows.each do |p|
          ptype = all_ref[p.id]
          @result[item][customer_rank][customer_name][ptype] ||={}
          @result[item][customer_rank][customer_name][ptype]['action'] ||={}
          @result[item][customer_rank][customer_name][ptype]['task'] ||={}
          @result[item][customer_rank][customer_name][ptype]['business'] ||={}
        end # End of Product Type Screen
      end

      i = 0
      for i in 0..br_name.size-1
        next if ((br_name[i] != 'Quotation') && CustomFields::IssueTracking.issue_state(issue) == :cancelled)
        if ((br_date[i] >= @date_from) && (br_date[i] <= @date_to))
          increase_summarized_value(@result, @total, [item,customer_rank,customer_name,ptype], :business, br_name[i], br_amount[i].to_f, 0.0)
          increase_summarized_value(@result, @total, [item,customer_rank,customer_name,ptype], :business, br_count[i])
        end
      end
    end # End of business record
    return @result, @total
  end

  def action_daily_rpt_2(date_from, date_to, rpt_ref)
    #Province -> Potential Rank -> Product Type -> Customer
    @date_from = date_from
    @date_to = date_to
    
    screen_all = get_all_screen
    cf_all = get_all_customfield
    #Potential Rank
    rank_screen = screen_all['potential rank']

    #Action
    action_screen = screen_all['action_revision']

    #Task
    task_screen = screen_all['task_detail']

    #Business Record
    business_screen = screen_all['business record']

    #Product Type
    product_screen = screen_all['product_type']

    #Customer
    customer_screen = screen_all['customer']
    
    #item ==> Estate_REF and Province REF
    if rpt_ref == 'Estate_REF'
      item_screen = screen_all['industrial estate']
    elsif rpt_ref == 'Province_REF'
      item_screen = screen_all['province']
    end
    cf_product_type = cf_all['production_type_ref']
    cf_customer = cf_all['customer_ref']
    cf_issue_tracking = cf_all['issue tracking']
    cf_action_type = cf_all['action type']
    cf_visit_purpose = cf_all['visit purpose']
    cf_task_purpose = cf_all['task purpose']
    cf_salesman = cf_all['salesman_ref']
    cf_quotation_date = cf_all['quotation date']
    cf_po_date = cf_all['po date']
    cf_invoice_date = cf_all['invoice date']
    cf_delivery_date = cf_all['delivery date']
    cf_payment_date = cf_all['payment date']
    cf_quotation_amount = cf_all['quotation amount']
    cf_po_amount = cf_all['po amount']
    cf_invoice_amount = cf_all['invoice amount']
    cf_delivery_amount = cf_all['delivery amount']
    cf_payment_amount = cf_all['payment amount']
    cf_rank = cf_all['potential_rank_ref']
    rpt_custom_field_id = cf_all[rpt_ref.downcase].id

    action_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id,cf_action_type.id,cf_visit_purpose.id]
    task_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_task_purpose.id]
    business_field_ids = [cf_issue_tracking.id, cf_customer.id, cf_salesman.id, cf_product_type.id, cf_quotation_date.id,  cf_po_date.id, cf_invoice_date.id, cf_delivery_date.id, cf_payment_date.id, cf_quotation_amount.id, cf_po_amount.id,  cf_invoice_amount.id, cf_delivery_amount.id, cf_payment_amount.id]

    @result = {} #Keep amount of all activity
    @total = {} #Keep total amount of all activity
    @total['action'] ||={}
    @total['task'] ||={}
    @total['business'] ||={}

    all_ref = gen_ref_values([product_screen.id,rank_screen.id,customer_screen.id,item_screen.id], [])
    custrank_ref = gen_ref_values(customer_screen.id, cf_rank.id)
    rptitem_ref = gen_ref_values(customer_screen.id, rpt_custom_field_id)

    # ------ Action ------
    action_rows = get_action_rows(action_screen.id, cf_issue_tracking.id, @date_from, @date_to)[0]
    
    a_rows = gen_rows_by_fields(action_rows, action_field_ids)
    
    action_rows.each do |fa|
      next if (customer_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_customer.id])) == 0
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(a_rows[fa.id][cf_product_type.id])) == 0

      item = rptitem_ref[customer_id]

      ptype = all_ref[product_type_id]

      action_type_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_action_type.id])
      customer_rank = custrank_ref[customer_id]
      customer_name = all_ref[customer_id]

      if action_type_id == 0
        action_type_name = 'Other'
      else
        action_type_name = Label.find(action_type_id).caption.name
      end

      if action_type_name == 'Visit'
        visit_purpose_id = CustomFields::ComboBox.cell_label_id(a_rows[fa.id][cf_visit_purpose.id])
        if visit_purpose_id == 0
          action_type_name = 'Routine'
        else
          action_type_name = Label.find(visit_purpose_id).caption.name
        end
      end

      if @result[item].nil?
        @result[item] ||={}
        @total[item] ||={}
        @total[item]['action'] ||={}
        @total[item]['task'] ||={}
        @total[item]['business'] ||={}

        rank_screen.rows.each do |r|
          rank_name = all_ref[r.id]
          @result[item][rank_name] ||={}
          @total[item][rank_name] ||={}
          @total[item][rank_name]['action'] ||={}
          @total[item][rank_name]['task'] ||={}
          @total[item][rank_name]['business'] ||={}

          product_screen.rows.each do |p|
            ptype = all_ref[p.id]
            @result[item][rank_name][ptype] ||={}
            @total[item][rank_name][ptype] ||={}
            @total[item][rank_name][ptype]['action'] ||={}
            @total[item][rank_name][ptype]['task'] ||={}
            @total[item][rank_name][ptype]['business'] ||={}
          end # End of Product Type Screen
        end # End of Potential Rank
      end

      if @result[item][customer_rank].nil?
        @result[item][customer_rank] ||={}
        @total[item][customer_rank] ||={}
        @total[item][customer_rank]['action'] ||={}
        @total[item][customer_rank]['task'] ||={}
        @total[item][customer_rank]['business'] ||={}

        product_screen.rows.each do |p|
          ptype = all_ref[p.id]
          @result[item][customer_rank][ptype] ||={}
          @total[item][customer_rank][ptype] ||={}
          @total[item][customer_rank][ptype]['action'] ||={}
          @total[item][customer_rank][ptype]['task'] ||={}
          @total[item][customer_rank][ptype]['business'] ||={}
        end # End of Product Type Screen
      end
      if @result[item][customer_rank][ptype][customer_name].nil?
        @result[item][customer_rank][ptype][customer_name] ||={}
        @result[item][customer_rank][ptype][customer_name]['action'] ||={}
        @result[item][customer_rank][ptype][customer_name]['task'] ||={}
        @result[item][customer_rank][ptype][customer_name]['business'] ||={}
      end

      increase_summarized_value(@result, @total, [item,customer_rank,ptype,customer_name], :action, action_type_name)

      # ------ Task ------
      task_rows = fa.detail_rows

      t_rows = gen_rows_by_fields(task_rows, task_field_ids)
      task_rows.each do |ft|
        task_purpose_id = CustomFields::RadioButton.cell_label_id(t_rows[ft.id][cf_task_purpose.id])

        if task_purpose_id == 0
          action_type_name = 'Other'
        else
          action_type_name = Label.find(task_purpose_id).caption.name
        end

        increase_summarized_value(@result, @total, [item,customer_rank,ptype,customer_name], :task, action_type_name)
      end
    end # End of @action_screen.rows.each
    # ------ Business Record ------
    row_ids = []
    sql_head = 'SELECT rows.* FROM rows INNER JOIN cells on rows.id = cells.row_id WHERE (rows.screen_id = ' + business_screen.id.to_s + ' AND (cells.field_id = '
    sql_last = " and cells.value between '" + @date_from + "' and '" + @date_to + "'))"
    sql = sql_head + cf_quotation_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_po_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_invoice_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_delivery_date.id.to_s + sql_last
    sql << ' union ' + sql_head + cf_payment_date.id.to_s + sql_last

    business_rows = Row.find_by_sql(sql)
    brows = gen_rows_by_fields(business_rows, business_field_ids)
    business_rows.each do |fb|
      issue = brows[fb.id][cf_issue_tracking.id]

      next if (customer_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_customer.id])) == 0
      next if (product_type_id = CustomFields::Reference.cell_ref_row_id(brows[fb.id][cf_product_type.id])) == 0

      ptype = all_ref[product_type_id]

      item = rptitem_ref[customer_id]

      customer_rank = custrank_ref[customer_id]
      customer_name = all_ref[customer_id]

      br_date = []
      br_amount = []
      br_name = ['Quotation','P/O','Delivery','Invoice','Payment']
      br_count = ['Quotation_count','P/O_count','Delivery_count','Invoice_count','Payment_count']

      br_date << brows[fb.id][cf_quotation_date.id]
      br_date << brows[fb.id][cf_po_date.id]
      br_date << brows[fb.id][cf_delivery_date.id]
      br_date << brows[fb.id][cf_invoice_date.id]
      br_date << brows[fb.id][cf_payment_date.id]

      br_amount << brows[fb.id][cf_quotation_amount.id]
      br_amount << brows[fb.id][cf_po_amount.id]
      br_amount << brows[fb.id][cf_delivery_amount.id]
      br_amount << brows[fb.id][cf_invoice_amount.id]
      br_amount << brows[fb.id][cf_payment_amount.id]

      if @result[item].nil?
        @result[item] ||={}
        @total[item] ||={}
        @total[item]['action'] ||={}
        @total[item]['task'] ||={}
        @total[item]['business'] ||={}

        rank_screen.rows.each do |r|
          rank_name = all_ref[r.id]
          @result[item][rank_name] ||={}
          @total[item][rank_name] ||={}
          @total[item][rank_name]['action'] ||={}
          @total[item][rank_name]['task'] ||={}
          @total[item][rank_name]['business'] ||={}

          product_screen.rows.each do |p|
            ptype = all_ref[p.id]
            @result[item][rank_name][ptype] ||={}
            @total[item][rank_name][ptype] ||={}
            @total[item][rank_name][ptype]['action'] ||={}
            @total[item][rank_name][ptype]['task'] ||={}
            @total[item][rank_name][ptype]['business'] ||={}
          end # End of Product Type Screen
        end # End of Potential Rank
      end

      if @result[item][customer_rank].nil?
        @result[item][customer_rank] ||={}
        @total[item][customer_rank] ||={}
        @total[item][customer_rank]['action'] ||={}
        @total[item][customer_rank]['task'] ||={}
        @total[item][customer_rank]['business'] ||={}

        product_screen.rows.each do |p|
          ptype = all_ref[p.id]
          @result[item][customer_rank][ptype] ||={}
          @total[item][customer_rank][ptype] ||={}
          @total[item][customer_rank][ptype]['action'] ||={}
          @total[item][customer_rank][ptype]['task'] ||={}
          @total[item][customer_rank][ptype]['business'] ||={}
        end # End of Product Type Screen
      end
      if @result[item][customer_rank][ptype][customer_name].nil?
        @result[item][customer_rank][ptype][customer_name] ||={}
        @result[item][customer_rank][ptype][customer_name]['action'] ||={}
        @result[item][customer_rank][ptype][customer_name]['task'] ||={}
        @result[item][customer_rank][ptype][customer_name]['business'] ||={}
      end

      i = 0
      for i in 0..br_name.size-1
        next if ((br_name[i] != 'Quotation') && CustomFields::IssueTracking.issue_state(issue) == :cancelled)
        if ((br_date[i] >= @date_from) && (br_date[i] <= @date_to))
          increase_summarized_value(@result, @total, [item,customer_rank,ptype,customer_name], :business, br_name[i], br_amount[i].to_f, 0.0)
          increase_summarized_value(@result, @total, [item,customer_rank,ptype,customer_name], :business, br_count[i])
        end
      end
    end # End of business record
    return @result, @total
  end
  def export_action_daily(result,total,date_from,date_to,header)
    time = Time.now.strftime('%Y%m%d%H%M%S')
	  file_name = "ActionReport_#{time}".gsub(' ','_')
	  file_path = "#{RAILS_ROOT}/public/ReportFile/#{file_name}.xls"
	  workbook  = Spreadsheet::WriteExcel.new(file_path);
	  format_title = workbook.add_format(:bold => 1,:color => 'black', :size => 14)
	  format_header = workbook.add_format(:bold => 1,:color => 'black', :bg_color => 27 ,:size => 12,:align => 'vcenter')
	  format_data = workbook.add_format(:color => 'black',:size => 10)
	  worksheet = workbook.add_worksheet

    col = header.length
    action = ['New Visit','Routine','Special',"Assembly Tech '10","Metalex '10",'Telephone','Email','Direct Mail','Other']
    task = ['Request Quotation','Project Followup','Delivery','Training','Claim Trouble','Other']
    business = ['Quotation','P/O','Delivery','Invoice','Payment']
    business_count = ['Quotation_count','P/O_count','Delivery_count','Invoice_count','Payment_count']

    worksheet.write(0,5,'Action Report',format_title)
    worksheet.write(1,5,date_from + '  to  ' + date_to,format_title)
    i = 4
    j = 0
    nlen = header.length + action.length + task.length + business.length + business_count.length - 1
    for i in 4..6
      for j in 0..nlen
        worksheet.write(i,j,'',format_header)
      end
      i+=1
      j=0
    end

    row = 4
    # Header
    i = 0
    for i in 0..col-1
      worksheet.write(row,i,header[i],format_header)
    end
    worksheet.write(row,(3+col),'Action (Count)',format_header)
    worksheet.write(row,(12+col),'Task (Count)',format_header)
    worksheet.write(row,(17+col),'Sales (Amount)',format_header)
    worksheet.write(row,(23+col),'Sales (Count)',format_header)
    row += 1
    worksheet.write(row,(1+col),'Visit',format_header)
    row += 1
    worksheet.write(row,col,'New',format_header)
    worksheet.write(row,col+1,'Routine',format_header)
    worksheet.write(row,col+2,'Special',format_header)
    worksheet.write(row,col+3,"Assembly Tech '10",format_header)
    worksheet.write(row,col+4,"Metalex '10",format_header)
    worksheet.write(row,col+5,'Tel',format_header)
    worksheet.write(row,col+6,'E-Mail',format_header)
    worksheet.write(row,col+7,'Direct Mail',format_header)
    worksheet.write(row,col+8,'Other',format_header)
    worksheet.write(row,col+9,'Request Quotation',format_header)
    worksheet.write(row,col+10,'Follow Project',format_header)
    worksheet.write(row,col+11,'Delivery',format_header)
    worksheet.write(row,col+12,'Training',format_header)
    worksheet.write(row,col+13,'Claim Trouble',format_header)
    worksheet.write(row,col+14,'Other',format_header)
    worksheet.write(row,col+15,'Quotation',format_header)
    worksheet.write(row,col+16,'P/O',format_header)
    worksheet.write(row,col+17,'Delivery',format_header)
    worksheet.write(row,col+18,'Invoice',format_header)
    worksheet.write(row,col+19,'Payment',format_header)
    worksheet.write(row,col+20,'Quotation',format_header)
    worksheet.write(row,col+21,'P/O',format_header)
    worksheet.write(row,col+22,'Delivery',format_header)
    worksheet.write(row,col+23,'Invoice',format_header)
    worksheet.write(row,col+24,'Payment',format_header)
    row += 1

    # Start to insert data
    result.each_with_index do |p, m| #1
      if col > 1
        worksheet.write(row,0,p[0],format_data) if p[1].empty?
        p[1].each_with_index do |b,n| #2
          if col > 2
            if b[1].empty?
              worksheet.write(row,0,p[0],format_data)
              worksheet.write(row,1,b[0],format_data)
              row += 1
            end
            b[1].each_with_index do |s,i| #3
              if col > 3
                if s[1].empty?
                  worksheet.write(row,0,p[0],format_data)
                  worksheet.write(row,1,b[0],format_data)
                  worksheet.write(row,2,s[0],format_data)
                  row += 1
                end
                s[1].each_with_index do |r,j| #4
                  if  col > 4
                    if r[1].empty?
                      worksheet.write(row,0,p[0],format_data)
                      worksheet.write(row,1,b[0],format_data)
                      worksheet.write(row,2,s[0],format_data)
                      worksheet.write(row,3,r[0],format_data)
                      row += 1
                    end
                    r[1].each_with_index do |c,k| #5
                      worksheet.write(row,0,p[0],format_data)
                      worksheet.write(row,1,b[0],format_data)
                      worksheet.write(row,2,s[0],format_data)
                      worksheet.write(row,3,r[0],format_data)
                      worksheet.write(row,4,c[0],format_data)
                      coln = 5
                      for name in action
                        worksheet.write(row,coln,c[1]['action'][name] ||='',format_data)
                        coln += 1
                      end
                      for name in task
                        worksheet.write(row,coln,c[1]['task'][name] ||='',format_data)
                        coln += 1
                      end
                      for name in business
                        worksheet.write(row,coln,c[1]['business'][name] ||='',format_data)
                        coln += 1
                      end
                      for name in business_count
                        worksheet.write(row,coln,c[1]['business'][name] ||='',format_data)
                        coln += 1
                      end
                      row += 1
                    end # End r[1] - 5
                  else
                    worksheet.write(row,0,p[0],format_data)
                    worksheet.write(row,1,b[0],format_data)
                    worksheet.write(row,2,s[0],format_data)
                    worksheet.write(row,3,r[0],format_data)
                    coln = 4
                    for name in action
                      worksheet.write(row,coln,r[1]['action'][name] ||='',format_data)
                      coln += 1
                    end
                    for name in task
                      worksheet.write(row,coln,r[1]['task'][name] ||='',format_data)
                      coln += 1
                    end
                    for name in business
                      worksheet.write(row,coln,r[1]['business'][name] ||='',format_data)
                      coln += 1
                    end
                    for name in business_count
                      worksheet.write(row,coln,r[1]['business'][name] ||='',format_data)
                      coln += 1
                    end
                    row += 1
                  end # End if col > 4
                end # End s[1] - 4
              else
                worksheet.write(row,0,p[0],format_data)
                worksheet.write(row,1,b[0],format_data)
                worksheet.write(row,2,s[0],format_data)
                coln = 3
                for name in action
                  worksheet.write(row,coln,s[1]['action'][name] ||='',format_data)
                  coln += 1
                end
                for name in task
                  worksheet.write(row,coln,s[1]['task'][name] ||='',format_data)
                  coln += 1
                end
                for name in business
                  worksheet.write(row,coln,s[1]['business'][name] ||='',format_data)
                  coln += 1
                end
                for name in business_count
                  worksheet.write(row,coln,s[1]['business'][name] ||='',format_data)
                  coln += 1
                end
                row += 1
              end # End if col > 3
            end # End b[1] - 3
          else
            worksheet.write(row,0,p[0],format_data)
            worksheet.write(row,1,b[0],format_data)
            coln = 2
            for name in action
              worksheet.write(row,coln,b[1]['action'][name] ||='',format_data)
              coln += 1
            end
            for name in task
              worksheet.write(row,coln,b[1]['task'][name] ||='',format_data)
              coln += 1
            end
            for name in business
              worksheet.write(row,coln,b[1]['business'][name] ||='',format_data)
              coln += 1
            end
            for name in business_count
              worksheet.write(row,coln,b[1]['business'][name] ||='',format_data)
              coln += 1
            end
            row += 1
          end # End if col > 2
        end # End p[1] - 2
      else
        worksheet.write(row,0,p[0],format_data)
        coln = 1
        for name in action
          worksheet.write(row,coln,p[1]['action'][name] ||='',format_data)
          coln += 1
        end
        for name in task
          worksheet.write(row,coln,p[1]['task'][name] ||='',format_data)
          coln += 1
        end
        for name in business
          worksheet.write(row,coln,p[1]['business'][name] ||='',format_data)
          coln += 1
        end
        for name in business_count
          worksheet.write(row,coln,p[1]['business'][name] ||='',format_data)
          coln += 1
        end
        row += 1
      end # End if col > 1
    end # End result - 1
    worksheet.write(row,0,'Grand Total',format_data)
    coln = col
    for name in action
      worksheet.write(row,coln,total['action'][name] ||=0,format_data)
      coln += 1
    end
    for name in task
      worksheet.write(row,coln,total['task'][name] ||=0,format_data)
      coln += 1
    end
    for name in business
      worksheet.write(row,coln,total['business'][name] ||=0,format_data)
      coln += 1
    end
    for name in business_count
      worksheet.write(row,coln,total['business'][name] ||=0,format_data)
      coln += 1
    end

    workbook.close
    send_file(file_path, :disposition => 'attachment', :encoding => 'utf8', :type => 'application/octet-stream')
  end

  # ====== Rank History Report with Export ======
  def rank_history
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/
  end

  def rank_history_report
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/
  end

  def export_rank_history(report_data,from_year,to_year,product_type_names,customer_names,rank_names)
    time = Time.now.strftime('%Y%m%d%H%M%S')
	  file_name = "RankReport_#{time}".gsub(' ','_')
	  file_path = "#{RAILS_ROOT}/public/ReportFile/#{file_name}.xls"
	  workbook  = Spreadsheet::WriteExcel.new(file_path);
	  format_a = workbook.add_format(:bold => 1,:color => 'black', :bg_color => 27 ,:size => 12,:merge => 1,:align => 'vcenter')
	  format_b = workbook.add_format(:color => 'black',:size => 10)
    format_c = workbook.add_format(:color => 'black',:size => 10,:align => 'vcenter')
	  worksheet = workbook.add_worksheet
    worksheet.write(0,0,'Customer',format_b)
    c = 1

    for year in from_year..to_year
      worksheet.merge_cells(0,c,0,c+((product_type_names.size*2) -1))
      worksheet.write(0,c,year,format_b)
      c += product_type_names.size * 2
    end
    c = 1
    for year in from_year..to_year
      product_type_names.each_value do |product_type_name|
        worksheet.merge_cells(1,c,1,c+1)
        worksheet.write(1,c,product_type_name.to_s,format_b)
        c += 2
      end
    end
    line = 2
    customer_names.each do |customer|
      c = 0
      worksheet.write(line,c,customer[1].to_s,format_b)
      c += 1
      for year in from_year..to_year
        product_type_names.each_key do |product_type_id|
          unless report_data[customer[0].to_s].nil?
            unless report_data[customer[0].to_s][year.to_s].nil?
              unless report_data[customer[0].to_s][year.to_s][product_type_id.to_s].nil?
                value = report_data[customer[0].to_s][year.to_s][product_type_id.to_s]
                worksheet.write(line,c,value.to_f.to_s,format_b)
                value = get_name_for_rank_value(report_data[customer[0].to_s][year.to_s][product_type_id.to_s],rank_names)
                worksheet.write(line,c+1,value.to_s,format_b)
              else
                worksheet.write(line,c,'',format_b)
                worksheet.write(line,c+1,'',format_b)
              end
            else
              worksheet.write(line,c,'',format_b)
              worksheet.write(line,c+1,'',format_b)
            end
          else
            worksheet.write(line,c,'',format_b)
            worksheet.write(line,c+1,'',format_b)
          end
          c+=2
        end
      end
      line += 1
    end
    workbook.close
    send_file(file_path, :disposition => 'attachment', :encoding => 'utf8', :type => 'application/octet-stream')
  end

  # ========== Compare Action Report ==========
  def compare_action
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/
  end

  def compare_action_report
    # ToDo: Change the hard coded report to a Report setting, or client base
    raise 'Hard coded report implementation' unless RAILS_ENV =~ /susbkk/
  end

  def export_compare_action(result,total,dfrom,dto,loop,rpt_type,rpt_name)
    time = Time.now.strftime('%Y%m%d%H%M%S')
	  file_name = "ActionReport_#{time}".gsub(' ','_')
	  file_path = "#{RAILS_ROOT}/public/ReportFile/#{file_name}.xls"
	  workbook  = Spreadsheet::WriteExcel.new(file_path);
	  format_title = workbook.add_format(:bold => 1,:color => 'black', :size => 14)
	  format_header = workbook.add_format(:bold => 1,:color => 'black', :bg_color => 27 ,:size => 12,:align => 'vcenter')
	  format_data = workbook.add_format(:color => 'black',:size => 10)
	  worksheet = workbook.add_worksheet

    worksheet.write(0,5,rpt_name + ' Report',format_title)
    i = 3
    j = 0
    n = 6 + (loop - 1) * 4
    for i in 2..3
      for j in 0..n
        worksheet.write(i,j,'',format_header)
      end
      i+=1
      j=0
    end

    row = 2
    # Header
    worksheet.write(row,0,'Sales Office',format_header)
    worksheet.write(row,1,'Salesman',format_header)
    worksheet.write(row,2,'Rank',format_header)
    nloop = 1
    for nloop in 1..loop
      datefrom_to = ''
      if rpt_type.to_i <= 2
        datefrom_to = (dto[nloop] == dfrom[nloop] ? dto[nloop] : dfrom[nloop] + ' to ' + dto[nloop])
      elsif rpt_type.to_i == 3
        datefrom_to = dfrom[nloop].to_date.month.to_s + '/' + dfrom[nloop].to_date.year.to_s
      elsif rpt_type.to_i == 4
        datefrom_to = 'Year ' + dfrom[nloop].to_date.year.to_s
      elsif rpt_type.to_i == 5
        datefrom_to = 'Q' + nloop.to_s + '/' + dfrom[nloop].to_date.year.to_s
      end
      worksheet.write(row,4 + (nloop - 1) * 4,datefrom_to,format_header)
      nloop += 1
    end
    row += 1
    nloop = 1
    for nloop in 1..loop
      worksheet.write(row,3 + (nloop - 1) * 4,'New',format_header)
      worksheet.write(row,4 + (nloop - 1) * 4,'Routine',format_header)
      worksheet.write(row,5 + (nloop - 1) * 4,'Special',format_header)
      worksheet.write(row,6 + (nloop - 1) * 4,'P/O',format_header)
      nloop += 1
    end
    row += 1

    result.each_with_index do |b, n|
      worksheet.write(row,0,b[0],format_data) #Sales Office
      b[1].each_with_index do |s,i|
        worksheet.write(row,1,s[0],format_data) #Salesman
        s[1].each_with_index do |r,j|
          worksheet.write(row,2,r[0],format_data) #Potential Rank
          nloop = 1
          for nloop in 1..loop
            worksheet.write(row,3 + (nloop - 1) * 4,r[1][nloop.to_s]['New Visit'] ||='-',format_data) #New Visit
            worksheet.write(row,4 + (nloop - 1) * 4,r[1][nloop.to_s]['Routine'] ||='-',format_data) #Routine
            worksheet.write(row,5 + (nloop - 1) * 4,r[1][nloop.to_s]['Special'] ||='-',format_data) #Special
            worksheet.write(row,6 + (nloop - 1) * 4,r[1][nloop.to_s]['P/O'] ||='-',format_data) #P/O
            nloop += 1
          end
          row += 1
        end
        #Add Total
        worksheet.write(row,2,'Total',format_data)
        nloop = 1
        for nloop in 1..loop
          worksheet.write(row,3 + (nloop - 1) * 4,total[s[0]][nloop.to_s]['New Visit'] ||=0,format_data) #New Visit
          worksheet.write(row,4 + (nloop - 1) * 4,total[s[0]][nloop.to_s]['Routine'] ||=0,format_data) #Routine
          worksheet.write(row,5 + (nloop - 1) * 4,total[s[0]][nloop.to_s]['Special'] ||=0,format_data) #Special
          worksheet.write(row,6 + (nloop - 1) * 4,total[s[0]][nloop.to_s]['P/O'] ||=0,format_data) #P/O
          nloop += 1
        end
        row += 1
      end
    end
    workbook.close
    send_file(file_path, :disposition => 'attachment', :encoding => 'utf8', :type => 'application/octet-stream')
  end
    
  def search 
    render :text => (RAILS_ENV =~ /development/) ? '<span class="missing_implementation">Implement how to display the search controls.</span>' : ''  
  end

  private

  def gen_ref_values(screen_ids, custom_field_ids = nil)
    if !screen_ids.is_a?(Array)
      gen_ref_values([screen_ids], custom_field_ids)
    elsif !custom_field_ids.is_a?(Array) && !custom_field_ids.nil?
      gen_ref_values(screen_ids, [custom_field_ids])
    else
      ref_values = {}
      block_size = 1000
      screen_ids.each do |s_id|
        conditions = { :rows => { :screen_id => s_id } }

        include = [:cells] if custom_field_ids

        offset = 0

        begin
          rows = Row.find(:all,
            :include => include,
            :limit => block_size,
            :offset => offset,
            :conditions => conditions,
            :order => 'id'
          )

          break if rows.empty?

          is_reference_custom_field = !custom_field_ids.nil? &&
            custom_field_ids.length == 1 &&
            custom_field_ids.first.to_i > 0 &&
            CustomFields::Reference.exists?(custom_field_ids.first.to_i)

          empty_value = is_reference_custom_field ? 'N/A' : '&nbsp;'

          rows.each do |r|
            ref_values[r.id] = r.description(custom_field_ids)
            ref_values[r.id] = empty_value if ref_values[r.id] =~ /missing_implementation/
          end
          
          offset += block_size
        end while true
      end
      
      ref_values
    end
  end

  def gen_rows_by_fields(rows, custom_field_field_ids)
    gen_rows = {}
    row_ids = rows.collect{|r| r.id }
    
    cells = Cell.find(:all,
      :conditions => {
        :cells => { :row_id => row_ids, :field_id => custom_field_field_ids }
      }
    )
    cells.each do |cell|
      gen_rows[cell.row_id] ||= {}
      gen_rows[cell.row_id][cell.field.id] = cell.value
    end
    return gen_rows
  end

  def gen_data_xls(field, cell, row)
    if !field.nil?
      case field
      when Fields::Data
        data = cell.to_text if !cell.nil?
      when Fields::HeaderInfo
        data = [field.evaluate_value(row)]
      when Fields::DetailInfo
        field_detail_screen_value = field.get_detail_screen_value(row.screen,row)
        detail_screen_value = field_detail_screen_value.size == 0 ? nil : field_detail_screen_value.join('/')
        data = [detail_screen_value]
      when Fields::Formula, Fields::Accumulation, Fields::ReferenceAttribute, Fields::CodeCombindedReferenceAttribute
        data = [field.html(field.evaluate_value(row))]
      when Fields::Comparison, Fields::Grouping
        data = [field.evaluate_value(row)]
      end
    else
      data = ''
    end
    data
  end
  
  def gen_data_csv(field, cell, row)
    if !field.nil?
      case field
      when Fields::Data
        data = cell.to_text if !cell.nil?
      when Fields::HeaderInfo
        data = [field.evaluate_value(row)]
      when Fields::DetailInfo
        field_detail_screen_value = field.get_detail_screen_value(row.screen,row)
        detail_screen_value = field_detail_screen_value.size == 0 ? nil : field_detail_screen_value.join('/')
        data = [detail_screen_value]
      when Fields::Formula, Fields::Accumulation, Fields::ReferenceAttribute, Fields::CodeCombindedReferenceAttribute
        data = [field.html(field.evaluate_value(row))]
      when Fields::Comparison, Fields::Grouping
        data = [field.evaluate_value(row)]
      end
    else
      data = ''
    end
    data
  end
  
  def get_action_rows(action_screen_id, cf_issue_tracking_id, date_from, date_to)
    issue_tracking_cells = Cell.find(:all,
      :joins => [:row],
      :conditions => {
        :rows => { :screen_id => action_screen_id },
        :cells => { :field_id => cf_issue_tracking_id }
      }
    )
    
    filter_row_ids = issue_tracking_cells.collect do |c|
      due_date = CustomFields::IssueTracking.cell_due_date(c.value)
      c.row_id if CustomFields::DateTimeField.check_date_in_range?(due_date, date_to, date_from)
    end.compact
    
    filter_rows = RevisionRow.find(:all,
      :include => [:rows],
      :conditions => {
        :rows => { :id => filter_row_ids }
      }
    )

    return filter_rows, issue_tracking_cells
  end

  #   increase_summarized_value(datas, totals, col_field_parents, col_type, col_field, value = 1, init_value = 0) -> nil
  # Dynamically build a summary tree
  #   datas = {}
  #   totals = {}
  #   increase_summarized_value(datas, totals, ['a','b'], :d, 'e', 1)
  #   increase_summarized_value(datas, totals, ['a','b'], :d, 'f', 2)
  #   increase_summarized_value(datas, totals, ['a','x'], :d, 'e', 3)
  #   increase_summarized_value(datas, totals, ['a','x'], :d, 'f', 4)
  #
  #   datas #=> {
  #         #     'a' => {
  #         #       'b' => {
  #         #         'd' => { 'e' => 1, 'f' => 1 }
  #         #       },
  #         #       'x' => {
  #         #         'd' => { 'e' => 3, 'f' => 4 }
  #         #       }
  #         #     }
  #         #   }
  #
  #   totals #=> {
  #          #     'd' => { 'e' => 4, 'f' => 5 },
  #          #     'a' => {
  #          #       'd' => { 'e' => 4, 'f' => 5 }
  #          #     }
  #          #   }
  def increase_summarized_value(datas, totals, col_field_parents, col_type, col_field, value = 1, init_value = 0)
    col_type_s = col_type.to_s
    a = totals
    b = datas

    (-1..col_field_parents.length-1).each do |i|
      if i >= 0
        [a, b].each{|h| h[col_field_parents[i]] ||= {}}

        a = a[col_field_parents[i]]
        b = b[col_field_parents[i]]
      end

      h = (i < col_field_parents.length-1) ? a : b

      h[col_type_s] ||= {}
      h[col_type_s][col_field] ||= init_value
      h[col_type_s][col_field] += value
    end
  end
   
end #End Class
