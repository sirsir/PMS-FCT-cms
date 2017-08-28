class RowsController < ApplicationController
  include ActionView::Helpers::DateHelper
  
  layout nil
  layout 'print', :only => [:print]

	protect_from_forgery :only => [:create]

  class << self
    def get_session_row_ids(session_id, screen_id, purge = false)
      vm = VirtualMemory::load(:session, session_id)

      vm[:filtered_row_ids] ||= {}
      ( purge ? vm[:filtered_row_ids].delete(screen_id) : vm[:filtered_row_ids][screen_id]) || []
    end

    def store_session_row_ids(session_id, screen_id, filtered_row_ids, filtered_row_ids_wo_limit = nil)
      vm = VirtualMemory::load(:session, session_id)
      
      vm[:filtered_row_ids] ||= {}
      vm[:filtered_row_ids][screen_id] = filtered_row_ids
      vm[:filtered_row_ids_wo_limit] ||= {}
      vm[:filtered_row_ids_wo_limit][screen_id] = filtered_row_ids_wo_limit if filtered_row_ids_wo_limit
      
      VirtualMemory::store(:session, session_id, vm)
    end

    def screen_from_action(params)
      action = params[:action].to_sym

      if !params[:screen_id].to_s.empty?
        screen = Screen.find(params[:screen_id])
      else
        case action
        when :index, :search, :new, :print, :export, :import
          screen = Screen.find(params[:id])
        when :update, :edit, :destroy, :fetch_row,
            :reference_attribute
          params[:id] = params[:row_id] if params[:id].to_i == 0
          if params[:id].to_i > 0
            row = Row.find(params[:id])
            screen = row.screen
          end
        when :reload_comboref
          ref_custom_field = CustomField.find(params[:custom_field_id])
          screen = ref_custom_field.screen
        when :parameter
          filed = Field.find(params[:field_id])

          screen = filed.screen
        end
      end

      screen
    end
  end # class << self

  def permission_mapping
    super.merge(
      {
        'print' => 'index',
        'reference_attribute' => 'index',
        'option_combined_reference' => 'edit',
        'option_combined_reference_group' => 'edit',
        'code_combined_reference' => 'edit',
        'code_combined_reference_group' => 'edit',
        'code_combined_reference_screen' => 'edit',
        'code_combined_reference_options' => 'edit',
        'parameter' => 'index',
        'model_look_up' => 'edit'
      }
    )
  end

  def screen_from_action(params)
    RowsController.screen_from_action(params) || super
  end

  # GET /rows
  # GET /rows.xml
  def index
    session[:search_filter_info] = {}
    @row_pattern = Row.find(params[:row_pattern_id].to_i) unless params[:row_pattern_id].nil?
    @row_ids = []
    @screen = session.active_screen
    @action_source = params[:action_source] || 'index'
    @quick_operation = params[:quick_operation] || 'index'
    @g_other = Label.descr_by_name('G_Other')
    @filtered_reference = params[:custom_fields] || {}
    rpp = ApplicationController.current_user.rows_per_page
    @pageno = (!@action_source.include?'page_') ? 1 : params[:pageno].gsub('/','')
    
    @view_mode = (params[:view_mode] || :list).to_sym
      
    @fields = @screen.fields.select{|f| f.display_in_list? }
    
    @readonly = !@screen.screen.allow_action?(:edit)

    @filtered_reference.delete_if do |key, value|
      case value
      when String
        value.strip.empty?
      when Hash
        value.delete_if{|k, v| v.strip.empty? || k == 'status' }.empty?
      end
    end

    case @action_source
    when 'index'
      options = @quick_operation == 'index' ? Row.filter_by_custom_fields(params[:id].to_i, {}, 'index', false) : {}

      @row_ids = options[:filtered_row_ids] || []
      @row_ids_wo_limit = options[:filtered_row_ids_wo_limit] || []
      @row_pattern = Row.find(options[:row_pattern_id]) unless options[:row_pattern_id].nil?
      session[:sort_field_id_order] = options[:sort_field_id_order] || []
      session[:filtered_reference] = @filtered_reference
      RowsController.store_session_row_ids(session.session_id, @screen.id, @row_ids, @row_ids_wo_limit)
    when 'search', 'page_search', 'page_index', 'relations'     
    
      session[:search_filter_info] = {}
      params[:custom_fields].nil? ? @filtered_reference = session[:filtered_reference] : session[:filtered_reference] = @filtered_reference
      
      @filtered_reference.each do |key, other|
        cf = CustomField.find(key)
        case cf
        when CustomFields::TextField
          fieldValue = other
          session[:search_filter_info][cf.name] = fieldValue
        when CustomFields::Reference
          fieldValue = Cell.find(:first, :conditions => {:row_id => other.values}).value
          session[:search_filter_info][cf.name] = fieldValue
        when CustomFields::DateTimeField
          count = other.length
          i=0
          for i in 0..(count-1)
            fieldDate = other.keys[i]
            fieldValue = other.values[i]
            session[:search_filter_info][fieldDate] = fieldValue
          end
        else
          fieldValue = other
          a=10
        end
      end
      
      screen_id = params[:request_id] || @screen.id
      purge = !params[:request_id].nil?
      @row_ids = RowsController.get_session_row_ids(session.session_id, screen_id.to_i, purge)

      if params.has_key?(:sort_field_id)
        session[:sort_field_id_order] = Row.reorder_field_sorting(session[:sort_field_id_order], params[:sort_field_id])
        
        @row_ids = Row.sort(@row_ids, session[:sort_field_id_order])
        
        RowsController.store_session_row_ids(session.session_id, @screen.id, @row_ids)
      end
    end
    
    @row_ids ||= []

    if @view_mode == :calendar
      @calendar_date = session[:calendar_date]
      @calendar_field_id = session[:calendar_field_id]
      @calendar_field_detail = session[:calendar_field_detail]

      rows = Row.find(@row_ids)
      calendar_field = Field.find(@calendar_field_id)
      
      @rows = {}
      
      rows.each do |r|
        row = calendar_field.screen.is_a?(RevisionScreen) ? r.latest_revision : r
        case calendar_field.custom_field
        when CustomFields::DateTimeField
          date = calendar_field.evaluate_value(row).to_date.to_s
        when CustomFields::IssueTracking
          cell = row.cell(calendar_field.custom_field_id)
          cell_value = cell.nil? ? {} : cell.value
          date = cell_value[@calendar_field_detail].to_date.to_s
        else
          raise 'Missing implementation'
        end
        @rows[date] ||= []
        @rows[date] << r
      end
    else
      @sort_field_id_order = session[:sort_field_id_order]

      @row_count = @row_ids.size

      #Page generator
      if @action_source == 'relations'
        pageno_from, pageno_to = 0, 4
      else
        pageno_from = (rpp*(@pageno.to_i-1))
        pageno_to = ((rpp*@pageno.to_i)-1)

        @maxpage = (@row_count.to_f / rpp).ceil
      end

      @row_ids = @row_ids[pageno_from..pageno_to] || []

      @rows = @screen.rows.find(:all,
        :conditions => {
          :rows => { :id => @row_ids }
        }
      )

      @rows.sort!{|a, b| @row_ids.index(a.id) <=> @row_ids.index(b.id)}

      if @screen.get_staff_ref_field_id
        @staff_row = User.find(session['user_id']).staff_row
      end
    end
    
    

    #~ ToDo: Push all code to the Row model
    # Onlt the @screen and @rows should be used to
    # render the view
    # 
    # @screen = Screen.find(params[:screen_id])
    # @rows = Row.find_index(params)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @rows }
    end
  end

  # GET /rows/fetch_row/1
  # GET /rows/fetch_row/1.xml
  def fetch_row
    row_id = params[:id].to_i

    @row = Row.find(row_id, :include => [:cells])
    screen = @row.screen

    if screen.get_staff_ref_field_id
      @staff_row = User.find(session['user_id']).staff_row
    end
    @readonly = !@staff_row.nil? && !@row.belongs_to?(@staff_row.id)
    
    user_row_id = ApplicationController.current_user.usage[:row_id]
    screen_filter_fs = screen.fields.select{|f| f.value[:filter] unless f.value.nil? }
    filter = []
    screen_filter_fs.each do |f|
      cells = @row.cells.select{|c| c.field_id == f.custom_field_id}
      filter += cells.collect{|c| c.row_id if user_row_id == CustomFields::Reference.cell_ref_row_id(c.value) }.compact
    end

    @readonly = false if !filter.empty? || screen_filter_fs.empty?

    respond_to do |format|
      format.html # fetch_row.html.erb
      format.xml  { render :xml => @row }
    end
  end

  # GET /rows/1
  # GET /rows/1.xml
  def show
    @screen = session.active_screen
    @row = Row.find(params[:id])

    @action_source = params[:action_source] || 'index'
    
    @readonly = !@screen.screen.allow_action?(:edit)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @row }
    end
  end

  # GET /rows/new
  # GET /rows/new.xml
  def new
    @sort_field_id_order = []
    @screen = Screen.find(params[:id])
    @users = User.find_active_users if @screen.has_loginfield?
	  @action_source = params[:action_source] || 'index'
	  @filtered_reference = params[:filtered_reference] || {}
	  row_model = "#{@screen.prefix}_row".classify.constantize
	  @row = row_model.new(:screen_id => @screen.id, :type => row_model)
    if @screen.get_staff_ref_field_id
      @staff_row = User.find(session['user_id']).staff_row
      @staff_ref_field_id = @screen.get_staff_ref_field_id
    end
    @gen_rows = nil

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @row }
    end
  end

  # GET /rows/edit/1
  def edit
    @screen = session.active_screen
    @action_source = params[:action_source]
    @filtered_reference = params[:filtered_reference] || {}
	  @row = Row.find(params[:id])
    @pageno = params[:pageno]

    custom_field_ids = []
    @screen.fields.each do |field|
      custom_field_ids << field.custom_field_id
    end
    custom_field_ids.compact! # Custom_field_id of datainfo is alway null
    #@gen_rows, @gen_values = gen_rows_by_fields_edit(@row,custom_field_ids)    
    
    custom_fields = custom_field_ids.collect{|cid| CustomField.find(cid)}
    custom_fields.each{ |cf| @detail_screen_id = cf.detail_screen_id if cf.is_a?(CustomFields::Calendar) }
      
    @users = User.find_active_users if @screen.has_loginfield?
    @own_row = true
    if @screen.get_staff_ref_field_id != nil
      @staff_row = User.find(session['user_id']).staff_row
      @staff_ref_field_id = @screen.get_staff_ref_field_id
      @own_row = @row.belongs_to?(@staff_row.id) if @staff_row
    end
    @readonly = !@staff_row.nil? && !@row.belongs_to?(@staff_row.id)
    @readonly &&= !@row.screen.allow_action?(:edit)
    
    respond_to do |format|
      format.html # edit.html.erb
      format.xml  { render :xml => @row }
    end
  end
  
  # GET /rows/edit/1
  def edit_unsave_row
    #
  end

  # POST /rows
  # POST /rows.xml
  def create
    screen = Screen.find(params[:screen_id])
    fulllog_value = {}

    row_attr = {}
    row_attr[:screen_id] = params.delete(:screen_id)
    row_attr[:remark] = params.delete(:remark)
    @form_content_reuse = params[:form_content_reuse]
    @save_as_new_copy = (params[:save_as_new_copy] =~ /true/i)

    row_model = params[:type].to_s.classify.constantize
    @row = row_model.new(row_attr)

    cells = params.delete(:cells) || {}

    # Get the binary data of the uploaded file
    #~ ToDo: Get the binary data for multiple the uploaded files
    file = cells[params['custom_field_id_of_file']]
    cells[params['custom_field_id_of_file']] = Upload.file_save(file) if !file.to_s.empty?

    # Force saving cells for searchable field
    field_ids_of_searchable = params[:field_ids_of_searchable]
    field_ids_of_searchable.each do |f_id|
      cells[f_id.to_s] = '' if params["screen_quick_search_text_#{f_id}"].to_s.empty?
    end unless field_ids_of_searchable.nil?
    
    cells.each do |field_id, value|
      cell = Cell.new(:field_id => field_id, :value => value)
      custom_filed = CustomField.find(field_id)

      fulllog_value[field_id.to_i] = change_type_of_value(custom_filed, cell)

      @row.cells << cell
      @row.load_cell_hash(cell)
    end
    
    ActiveRecord::Base.transaction do
      @row.cells.each do |c|
        case c.field
        when CustomFields::AutoNumbering
          CustomFields::AutoNumbering.set_cell_temp_text(c.value)
        when CustomFields::Calendar
          null_date = Date.null_date
          if c.custom_field.monthly_format?
            selected_date = Date.new(c.value[:year].to_i, null_date.month, null_date.day)
            selected_date = CustomFields::DateTimeField.begin_of_period(selected_date, :year)
            new_hash = {:selected_date => selected_date.to_date.to_s}
            c.value.replace(new_hash)
          end
        end
      end

      # ToDo: Move this code to a client base code
      WorkFlow.auto_close_new_visit_action(screen, cells) if Rails.configuration.client_code =~ /susbkk/

      if @row.save && @row.cells.all? {|c| c.save }
        save_full_log :created, 1, fulllog_value

        # ToDo: Move this code to a client base code
        WorkFlow.set_customer_first_p_o(screen, @row) if Rails.configuration.client_code =~ /susbkk/

        @row.cells.each do |c|
          case c.field
          when CustomFields::Calendar
            if c.custom_field.monthly_format?
              CustomFields::Calendar.create_detail_rows(c.id, c.value[:selected_date], c.field.detail_screen.id)
            end
          when CustomFields::DateTimeRange
            CustomFields::DateTimeRange.create_date_time_range_value(c, {:from => c.value[:from], :to => c.value[:to]})
          end
        end
      end

      raise ActiveRecord::Rollback unless @row.errors.empty?

      @row.cells.each do |c|
        case c.field
        when CustomFields::AutoNumbering
          auto_numbering_text = CustomFields::AutoNumbering.increase(c.field_id, @row.cells)
          CustomFields::AutoNumbering.set_cell_text(c.value, auto_numbering_text)
          c.save
        end
      end
    end

    screen.reload_uncached_association

    respond_to do |format|
      format.html # create.html.erb
      format.xml  { render :xml => @row }
    end unless @save_as_new_copy
  end
  
  # POST /rows
  # POST /rows.xml
  def create_unsave_row
    @row = Row.new(:screen_id => params[:screen_id],:remark => params[:remark].to_yaml)
    @cells = params[:cells]
    @cells.each do |field_id, value|
      Cell.new(:row_id => @row.id, :field_id => field_id, :value => value.to_yaml)
    end
    format.html { render :controller => 'rows', :action => 'create'}
  end
  
  # PUT /rows/1
  # PUT /rows/1.xml
  def update
    @row = Row.find(params[:id])
    @action_source = params[:action_source]
    screen = @row.screen
    
    @save_as_new_copy = (params[:save_as_new_copy] =~ /true/i)

    if @save_as_new_copy
      params[:screen_id] = screen.id
      params[:type] = @row.class.name
      params[:cells_org] = params[:cells]
      params[:remark_org] = params[:remark]

      self.create
      
      params[:cells] = params[:cells_org]
      params[:remark] = params[:remark_org]
    end
      
    fulllog_value = {}
    @row.full_logs.each do |fl|
      fulllog_value.merge!(fl.value)
    end unless @row.full_logs.nil?

    last_log = @row.full_logs.last
    log_seq_no = last_log.nil? ? 1 : last_log.seq_no.to_i + 1
    log_action = last_log.nil? ? :created : :modified

    cells = params.delete(:cells) || {}
    # Use for upload file field
    if params['original_path_file']
      file = cells[params['custom_field_id_of_file']].to_s
      cells[params['custom_field_id_of_file']] = (file.empty?) ? params['original_path_file'] : Upload.file_save(file)
    end

    # Check value in searchable field id null?
    field_ids_of_searchable = params[:field_ids_of_searchable]
    field_ids_of_searchable.each do |f_id|
      cells[f_id.to_s] = '' if params["screen_quick_search_text_#{f_id}"] == ''
    end if field_ids_of_searchable

    #~ Create cells for new fields
    custom_field_ids = cells.collect{|field_id, value| field_id.to_i }
    current_custom_field_ids = @row.cells.collect{|c| c.field_id }.uniq
    new_custom_field_ids = custom_field_ids - current_custom_field_ids

    new_custom_field_ids.each do |cf_id|
      cell = Cell.new(:field_id => cf_id, :value => nil)
      @row.cells << cell
      @row.load_cell_hash(cell)
    end

    #~ Update existing cells, and clear missing values
    @row.screen.fields.each do |f|
      unless f.custom_field.nil?
        cell = @row.cell(f.custom_field_id)
        cell.value = cells.delete(cell.custom_field_id.to_s) if cell
        each_field_fulllog_value = change_type_of_value(f.custom_field, cell) if cell
        if last_log.nil?
          fulllog_value[f.custom_field_id] = each_field_fulllog_value unless each_field_fulllog_value.nil?
        else
          if (fulllog_value.has_key?(f.custom_field_id)) && (fulllog_value[f.custom_field_id] == each_field_fulllog_value)
            fulllog_value.delete(f.custom_field_id)
          else
            fulllog_value.merge!({f.custom_field_id => each_field_fulllog_value})
          end
        end
      end
    end
    @row.cells.each do |c|
      case c.field
      when CustomFields::Calendar
        null_date = Date.null_date
        if c.custom_field.monthly_format?
          selected_date = Date.new(c.value[:year].to_i, null_date.month, null_date.day)
          selected_date = CustomFields::DateTimeField.begin_of_period(selected_date, :year)
          new_hash = {:selected_date => selected_date.to_date.to_s}
          c.value.replace(new_hash)
        end
      when CustomFields::UploadImage
        if params[:remove_image].has_key?(c.field_id.to_s)
          begin
            File.delete("#{RAILS_ROOT}/public/attachments/#{c.value}")
          rescue Exception
            # Nothing to do
          end
          c.value = ''
        end if params.has_key?(:remove_image)
      end
    end

    @row.remark = params.delete(:remark)

    ActiveRecord::Base.transaction do
      if @row.save
        #~ Save the cells
        @row.cells.each do |c|
          c.save
        end

        if !fulllog_value.empty?
          if log_action == :created
            (save_full_log log_action, log_seq_no, fulllog_value, @row.created_at)
          else
            (save_full_log log_action, log_seq_no, fulllog_value)
          end
        end

        @row.cells.each do |c|
          case c.field
          when CustomFields::Calendar
            params.each do |key,value|
              if !(key =~ /calendar_value_row/).nil?
                detail_row_id = c.field.get_row_id(key)
                value.each do |field_id,val|
                  calendar_value_cell = Cell.find(:first, :conditions=>{:row_id => detail_row_id, :field_id => field_id})
                  calendar_value_cell.nil? ?
                    Cell.create(:row_id => detail_row_id, :field_id => field_id , :value => val) :
                    calendar_value_cell.update_attribute(:value, val)
                end
              end
            end
            if Cells::CalendarValue.find(:first, :conditions => {:cell_id => c.id}).nil?
              CustomFields::Calendar.create_detail_rows(c.id, c.value[:selected_date], c.field.detail_screen.id)
            end
          when CustomFields::DateTimeRange
            cell_date_time_range = c.date_time_range_value
            cell_date_time_range.date_time_from = c.value[:from]
            cell_date_time_range.date_time_to = c.value[:to]
            cell_date_time_range.save
          end
        end

        # ToDo: Save triggered like record
        WorkFlow.set_customer_first_p_o(screen, @row) if Rails.configuration.client_code =~ /susbkk/
      end
    end

    screen.reload_uncached_association

    if @save_as_new_copy
      render :action => 'create'
    else
      respond_to do |format|
        format.html # create.html.erb
        format.xml  { render :xml => @row }
      end
    end
  end

  # DELETE /rows/1
  # DELETE /rows/1.xml
  def destroy
    row_ids = params[:row_ids] || [params[:id]]
    
    #~ Is there any rows that do not exist?
    missing_rows = row_ids.any?{|r_id| !Row.exists?(r_id) }
    
    @result = Row.new
    @rows = []

    unless missing_rows
      @rows = row_ids.collect do |r_id|
        @row = Row.find(r_id)
        screen = @row.screen
        last_log = @row.full_logs.last

        case @row
        when RevisionRow
          if @row.rev_no == 0
            @row.errors.add('Unable to delete the primary revision. This operation')
          end
        end
        
        if @row.errors.empty? && @row.destroy
          log_seq_no = last_log.nil? ? 1 : last_log.seq_no.to_i + 1

          (save_full_log :deleted, log_seq_no)

          screen.reload_uncached_association
        else
          @row.errors.full_messages.each{|m| @result.errors.add(m) }
        end

        @row if @row.errors.empty?
      end.compact
    else
      msg = row_ids.size == 1 ? 'The record has' : 'Some records have'
      
      @result.errors.add("#{msg} already been removed from the system. Please refresh the page. This operation")
    end
    
    respond_to do |format|
      format.html # destroy.html.erb
      format.xml  { render :xml => @row }
    end
  end
  
  def export
    # redirect to report controller
    redirect_to :controller=> 'reports', :action => 'export', :id => params[:id], :action_source => params[:action_source]
  end

  def import
    @screen = session.active_screen
    
    params[:step] ||= :import

    @parent_row_id = params[:parent_row_id].to_i
    @operation_area_id = params[:operation_area_id] || params[:ajax_result_id] || "operation_area_#{@screen.id}"
    @starting_row = [params[:starting_row].to_i, 1].max
    @fields = params[:fields] || {}
    @allow_update = !(params[:allow_update].to_s =~ /true/i).nil?
    @filename_hash = params[:filename_hash]
    
    flash.clear
    params[:flash].each {|k,v| flash[k.to_sym] = v } if params.has_key?(:flash)
    
    case params[:step].to_sym
    when :import
    when :import_selected_file
      file = params['file']
      if !@filename_hash.nil?
        @next_step = :import_select_offset
      elsif File.extname(file.original_filename) =~ /#{params[:import][:file_type]}/i
        tmp_filename = Upload.tmp_save(file)
        filename = File.expand_path(tmp_filename, File.join(RAILS_ROOT, 'public'))
        
        @filename_hash = filename.hash
        
        vm = VirtualMemory.load(:screen_import, @filename_hash)

        vm[:filename] = filename
        begin
          vm[:file_content] = CSV.read(filename)
        rescue Exception => ex
          flash[:error] = 'Invalid input file format'
        end

        if flash[:error].nil?
          FileUtils.rm(filename)

          vm[:file_content] = vm[:file_content].select{|data| data.first !~ /^(#|\/{2})/}

          if vm[:file_content].first == @screen.csv_field_header
            @starting_row = 2
            @fields = {}
            @screen.fields.select{|f| f.allow_import? }.each_with_index{|f, i| @fields[i] = f.id }
            @fields[@fields.size] = 0

            vm[:from_template] = true
            vm[:starting_row] = @starting_row
            vm[:field_mappings] = @fields
            vm[:allow_update] = @allow_update
          end

          VirtualMemory.store(:screen_import, @filename_hash, vm)
          
          @next_step = :import_select_offset
        else
          @next_step = :import
        end
      else
        @next_step = :import
      end

      params[:step] = :import_next_step
    when :import_select_offset
      vm = VirtualMemory.load(:screen_import, @filename_hash)

      @file_content = vm[:file_content]
      @file_content << ['---------- End of File ----------']
    when :import_selected_offset
      vm = VirtualMemory.load(:screen_import, @filename_hash)
      
      unless vm[:starting_row] == @starting_row
        vm[:starting_row] = @starting_row
        
        VirtualMemory.store(:screen_import, @filename_hash, vm)
      end
      
      @next_step = :import_map_field
      params[:step] = :import_next_step
    when :import_map_field
      vm = VirtualMemory.load(:screen_import, @filename_hash)
      
      @file_content = vm[:file_content].last(vm[:file_content].size-(@starting_row-1))

      @col_count = @file_content.inject(0) do |n, c|
        cnt = c.size
        cnt > n ? cnt : n
      end
    when :import_mapped_field
      validate_result = @screen.validate_import(@filename_hash, @starting_row, @fields)
      
      if validate_result[:status] == :error
        @import_result = validate_result
        @next_step = :import_result
        flash[:error] = validate_result[:flash_error]
      else
        vm = VirtualMemory.load(:screen_import, @filename_hash)
        
        vm[:executed_at] = Time.now
        vm[:field_mappings] = @fields
        vm[:allow_update] = @allow_update

        VirtualMemory.store(:screen_import, @filename_hash, vm)

        @next_step = :import_execute
      end
        
      params[:step] = :import_next_step
    when :import_execute
      begin
        block = params[:block].to_i
        limit = 10

        ajax_url_options = {
          :action => :import,
          :parent_row_id => @parent_row_id,
          :filename_hash => @filename_hash,
          :starting_row => @starting_row,
          :fields => @fields,
          :allow_update => @allow_update,
          :ajax_result_id => params[:ajax_result_id]
        }

        if params[:screen_index_updated].to_s =~ /true/i
          @import_result = @screen.import(
            @filename_hash, (block * limit) + @starting_row, @fields.to_hash,
            :check_unique => true, :parent_row_id => @parent_row_id, :limit => limit,
            :allow_update => @allow_update
          )

          ajax_url_options[:block] = block + 1
        else
          if params[:screen_index_updated].to_s =~ /false/i
            vm = VirtualMemory.load(:screen_index, @screen.id)
            if (vm[:updated_at] || Time.at(0)) < Time.now - 60*60*3
              @screen.rebuild_index
              
              custom_fields = @screen.fields.collect{|f| f.custom_field if f.custom_field.respond_to?(:rebuild_index_by_screen) }.compact
              custom_fields.each do |cf|
                cf.rebuild_index_by_screen(@screen, nil, false)
              end
            end
          else
            notification = 'Rebuidling Screen Index...'
          end

          vm = VirtualMemory.load(:screen_import, @filename_hash)

          @import_result = {
            :status => :inprogress,
            :file_content => vm[:file_content],
            :row_count => 0,
            :errors => [],
            :executed_at => vm[:executed_at]
          }

          vm = nil

          params[:screen_index_updated] = !(params[:screen_index_updated].to_s =~ /false/i).nil?
        end
        
        ajax_url_options[:screen_index_updated] = params[:screen_index_updated].to_s
        
        if @import_result[:status] == :inprogress
          ui_feedback = import_execute_feedback(params[:ajax_result_id], @import_result[:file_content].size, @import_result[:row_count], @import_result[:errors].size, @import_result[:executed_at], notification)
          ajax_url_options[:step] = :import_execute
          url = url_for(ajax_url_options)
        else
          ajax_url_options[:step] = :import_result
          ajax_url_options[:flash] = {}
          if @import_result[:errors].empty?
            ajax_url_options[:flash][:notice] = 'Succesfully imported the data.'
          else
            ajax_url_options[:flash][:error] = 'Some data were rejected.'
          end
          ui_feedback = <<JAVASCRIPT
fncAjaxUpdater('#{params[:ajax_result_id]}','#{url_for(ajax_url_options)}');
JAVASCRIPT
          if Row.exists?(@parent_row_id.to_i)
            parent_row = Row.find(@parent_row_id)
            case parent_row
            when RevisionRow
              parent_row.clear_cache
              ui_feedback << <<JAVASCRIPT
fncUpdateTrToTableContent(#{parent_row.screen_id}, #{parent_row.id});
fncUpdateTrToTableContent(#{parent_row.header_row.screen_id}, #{parent_row.header_row.id});
JAVASCRIPT
            end
          end
          url = nil
        end
      rescue Exception => ex
        log_error(ex) if logger

        @import_result = VirtualMemory.load(:screen_import, @filename_hash)
        ui_feedback = import_execute_feedback(params[:ajax_result_id], @import_result[:file_content].size, @import_result[:row_count].to_i, [@import_result[:errors]].compact.size, @import_result[:executed_at], ex)
        url = nil
      end
      update_ui_and_perform_next(ui_feedback, url)
      return
    when :import_result
      @import_result = VirtualMemory.load(:screen_import, @filename_hash)
    when :download
      vm = VirtualMemory.load(:screen_import, @filename_hash)

      CSV.open(vm[:filename], 'wb') do |csv|
        csv << @screen.csv_field_header if vm[:from_template]
        vm[:errors].each do |e|
          csv << e[:row]
        end
      end
      
      send_file vm[:filename], :type => 'text/csv'
      return
    when :log
      vm = VirtualMemory.load(:screen_import, @filename_hash)
      ext = File.extname(vm[:filename])
      log_filename = vm[:filename].gsub(ext, '.log')
      
      File.open(log_filename, 'wb') do |f|
        vm.delete(:file_content)
        vm[:field_mappings].each {|i, f_id| f_id << " #{Field.find(f_id).full_name}" if f_id.to_i > 0 }
        
        f << vm.to_yaml
      end

      send_file log_filename, :type => 'text/plain'
      return
    when :template
      filename = File.join(Rails.root, 'tmp/cache/fw', "#{@screen.label_descr.tableize.gsub(/ /, '_') }_template.csv")
      CSV.open(filename, 'wb') do |csv|
        csv << @screen.csv_field_header
      end

      send_file filename, :type => 'text/csv'
      return
    when :cancel
      @next_step = :import
      params[:step] = :import_next_step
    end
    
    render :action => params[:step]
  end

  def edit_header
    @row = Row.find(params[:id])
  end
  
  def new_header
    @screen = session.active_screen
    @row = Row.new(:screen_id => @screen.id)
    @cell = [] #=> declare for using '>>' syntax
    @screen.fields.each do |f|
      @cell << Cell.new(:field_id => f.custom_field_id)
    end
	  
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @row }
    end
  end

  def search
    action_source = params[:action_source] || 'search'
    screen_id = params[:id].to_i
    custom_fields = params[:custom_fields] || {}
    view_mode = params[:view_mode].to_i > 0 ? :calendar : :list
    
    if view_mode == :calendar
      calendar_field_id = params[:view_mode].to_i
      calendar_field_detail = params[:view_mode].gsub(/^\d+_?/, '')
      calendar_field = Field.find(calendar_field_id)
      calendar_custom_field_id = calendar_field.custom_field_id
      calendar_date = Date.today
    end
    
    custom_fields.each do |key, value|
      custom_field = CustomField.find(key)
      if custom_field.is_a?(CustomFields::Calendar)
        if value[:year].to_s.strip.empty?
          value.replace({})
        else
          null_date = Date.null_date
          selected_date = Date.new(value[:year].to_i, null_date.month, null_date.day)
          selected_date = CustomFields::DateTimeField.begin_of_period(selected_date, :year)
          new_hash = {'selected_date' => selected_date.to_date.to_s}
          value.replace(new_hash)
        end
      elsif key.to_i == calendar_custom_field_id
        key_prefix = "#{calendar_field_detail}_" unless calendar_field_detail.empty?
        key_from = "#{key_prefix}from"
        key_to = "#{key_prefix}to"
        
        if !value[key_from].empty?
          calendar_date = value[key_from].to_date
        elsif !value[key_to].empty?
          calendar_date = value[key_to].to_date
        end

        value[key_from] = calendar_date.beginning_of_month.beginning_of_week.to_s
        value[key_to] = calendar_date.end_of_month.end_of_week.to_s
        value['status'] = 'set'
      end
    end
    @screen = session.active_screen

    @filter_errors = Field.validate_filters(screen_id, custom_fields)

    if @filter_errors[:required].empty? && @filter_errors[:invalid].empty?
      options = Row.filter(params[:id].to_i,
        :custom_fields => custom_fields,
        :action_source => action_source,
        :include_other_user => params[:include_other_user],
        :include_updated_at_filter => !params[:include_old_data] && view_mode == :list,
        :sort_results => view_mode == :list
      )

      filtered_row_ids = options[:filtered_row_ids] || []
      filtered_row_ids_wo_limit = options[:filtered_row_ids_wo_limit] || []
      row_pattern_id = options[:row_pattern_id]
      session[:sort_field_id_order] = options[:sort_field_id_order] || []

      session[:filter_custom_fields] = custom_fields
      session[:include_other_user] = params[:include_other_user]
      session[:include_old_data] = params[:include_old_data]
      session[:calendar_date] = calendar_date
      session[:calendar_field_id] = calendar_field_id
      session[:calendar_field_detail] = calendar_field_detail

      screen_id = request_id = request.id if action_source == 'relations'
      
      RowsController.store_session_row_ids(session.session_id, screen_id, filtered_row_ids, filtered_row_ids_wo_limit)
      
      redirect_to :action => 'index',
        :id => params[:id],
        :action_source => action_source,
        :custom_fields => custom_fields,
        :row_pattern_id => row_pattern_id,
        :include_other_user => params[:include_other_user],
        :request_id => request_id,
        :view_mode => view_mode
    else
      @filter_errors[:required].to_a
      @filter_errors[:invalid].to_a

      respond_to do |format|
        format.html # search.html.erb
        format.xml  { render :xml => @row }
      end
    end
  end

  def special_search
    # ToDo: Defined which field/screen to use special search
    raise 'Hard coded Screen name "Customer"' unless RAILS_ENV =~ /susbkk/
  end

  def relations
    screen = Screen.find(params[:screen_id].to_i)
    @screens = screen.dependencies
  
    unless @screens.empty?
      @custom_fields = {}
      screen.reference_custom_field_ids.each do |cf_id|
        @custom_fields[cf_id] = { :row_id => params[:id] }
      end
      screen.scr_custom_fields.each do |scr_cf|
        @custom_fields[scr_cf.id] = params[:id]
      end
    end
      
    respond_to do |format|
      format.html
      format.xml  { render :xml => @screens }
    end
  end

  def quick_add
    # ToDo: Input values for the 'Mandetory' fields
    raise 'Hard coded CustomField name "name"' unless RAILS_ENV =~ /susbkk/
  end

  def quick_search
      
    screen = Screen.find(params[:screen_id].to_i)
    text = params[:text].to_s.strip
    @field = Field.find(params[:field_id].to_i)
    @result = screen.find_by_row_desctiption(text, @@user[:login], @field.custom_field)
    @input_id = params[:input_id].to_s
    @result_row_id = params[:result_row_id]
    @relate_to = params[:relate_to] || ''
    @from_cf_id = params[:from_cf_id] || ''
    respond_to do |format|
      format.html
      format.xml  { render :xml => @rows }
    end
  end

  def reload_comboref
    screen_id = params[:screen_id].to_i
    @custom_field_id = params[:custom_field_id]
    cf = CustomField.find(@custom_field_id.to_i)
    reference_row_id = params[:row_id].to_i
    from_cf_id = params[:from_cf_id]
    filter_row_ids = []
    cells = Cell.find(:all,
      :joins => [:row],
      :conditions  => {
        :rows => { :screen_id => cf.screen_id },
        :cells => { :field_id => from_cf_id }
      }
    )
    filter_cells = cells.collect{|c| c if CustomFields::Reference.cell_ref_row_id(c.value) == reference_row_id}.compact
    filter_cells.each{|c| filter_row_ids << c.row_id}
      
    rows = Row.find(filter_row_ids)
    @results = rows.sort{|a,b| a.description <=> b.description}

    if screen_id > 0
      screen = Screen.find(screen_id)
      @field = screen.fields.select{|f| f.custom_field_id == @custom_field_id.to_i }.first
    end
    
    respond_to do |format|
      format.html
      format.xml  { render :xml => @rows }
    end
  end

  def gen_rows_by_fields(rows,custom_field_field_ids)
    gen_rows = {}
    row_ids = []
    cell_values = []
    all_values = {}
    if rows.is_a?Row
      row_ids << rows.id
    else
      row_ids = rows.collect{|r| r.id }
    end

    cells = Cell.find(:all, :conditions=>['row_id in (?) and field_id in (?)', row_ids, custom_field_field_ids])
    cells.each do |cell|
      cell_values = []
      row_id = cell.row_id
      custom_field_id = cell.field_id
      gen_rows[row_id] = {} if gen_rows[row_id].nil?
      gen_rows[row_id][custom_field_id] = cell.value == '' ? '&nbsp;' : cell.value
      if !cell.value.is_a?(HashWithIndifferentAccess)
        if cell.value.is_a?(Array)
          cell_values += cell.value.collect {|i| i.to_i if i.to_i > 0 }.compact if cell.value.length > 0
        else
          cell_values << cell.value.to_i if cell.value.to_i > 0
        end
      end
      all_values.merge!(gen_values(cell_values)) if cell_values != []
    end
    return gen_rows, all_values
  end

  def gen_rows_by_fields_edit(rows,custom_field_field_ids)
    gen_rows = {}
    row_ids = []
    cell_values = []
    if rows.is_a?Row
      row_ids << rows.id
    else
      rows.each do  |row|
        row_ids << row.id
      end
    end

    cells = Cell.find(:all, :conditions=>['row_id in (?) and field_id in (?)', row_ids, custom_field_field_ids])
    cells.each do |cell|
      row_id = cell.row_id
      custom_field_id = cell.field_id
      gen_rows[row_id] = {} if gen_rows[row_id].nil?
      gen_rows[row_id][custom_field_id] = cell
      if !cell.value.is_a?(HashWithIndifferentAccess)
        if cell.value.is_a?(Array)
          cell_values += cell.value.collect {|i| i.to_i if i.to_i > 0 }.compact if cell.value.length > 0
        else
          cell_values << cell.value if cell.value.to_i > 0
        end
      end
    end
    return gen_rows, gen_values(cell_values)
  end

  def gen_values(rows)
    gen_rows = {}
    cells = Cell.find(:all, :conditions=>['row_id in (?) and field_id = 186', rows])
    row_id = rows.join(',')
    gen_rows[row_id] = cells.collect do |cell|
      cell.value == '' ? '&nbsp;' : cell.value if gen_rows[row_id].nil?
    end.compact.join(', ')
    return gen_rows
  end

  def option_combined_reference_group()
    @screen_id = params[:screen_id]
    @input_name = params[:input_name]
    @multiplier_row = Row.find(params[:row_id].to_i) if params[:row_id].to_i > 0
    @scr_row = Row.find(params[:scr_row_id].to_i)
    @sub_scr_row = Row.find(params[:sub_scr_row_id].to_i)
    @index = params[:index].to_i
    @field = Field.find(params[:field_id].to_i)

    respond_to do |format|
      format.html
      format.xml  { render :xml => @screens }
    end
  end

  def code_combined_reference
    @screen_id = params[:screen_id]
    @field = Field.find(params[:field_id].to_i)
    @input_name = params[:input_name]
    
    scr_row_id = params[:scr_row_id].to_i
    
    if scr_row_id > 0 then
      @scr_row = Row.find(scr_row_id)

      scr_row_cell_value = @scr_row.cell(@field.ocr_field.scr_field.custom_field_id).value
      group_index = CustomFields::ScreenCombindedReference.group_index(scr_row_cell_value)
      
      unless group_index.nil?
        sub_scr_row_id = scr_row_cell_value[:parts][group_index][:screen_combinded_reference_row_id]
        @sub_scr_row = Row.find(sub_scr_row_id) if sub_scr_row_id > 0

        multiplier_screen_id = scr_row_cell_value[:parts][group_index][:screen_id]
        @multiplier_row = @scr_row if multiplier_screen_id < 0
      end
      
      options = @field.custom_field.options(@scr_row, @field, [], true )
      
      @available_options = { 0 => [options[:available_options]].flatten.compact }
    end

    @ccr_result_id_prefix = params[:ccr_result_id_prefix]
    @next_ccr_result_id = params[:next_ccr_result_id]
    
    respond_to do |format|
      format.html
      format.xml  { render :xml => @screens }
    end
  end

  def code_combined_reference_group
    @screen_id = params[:screen_id]
    @field = Field.find(params[:field_id].to_i)
    @input_name = params[:input_name]

    parent_scr_row_id = params[:parent_scr_row_id].to_i
    @parent_scr_row = Row.find(parent_scr_row_id) if parent_scr_row_id > 0
    @scr_row = params[:scr_row_id].nil? ? nil : Row.find(params[:scr_row_id].to_i) # CB
    @sub_scr_row = Row.find(params[:sub_scr_row_id].to_i)

    multiplier_row_id = params[:selected_value].to_i
    @multiplier_row = Row.find(multiplier_row_id) if multiplier_row_id > 0

    @selected_values = params[:selected_options] || []
    @selected_values << params[:selected_value] unless params[:selected_value].to_s.strip.empty?
    options = @field.custom_field.options(@scr_row, @field, @selected_values, true)

    @available_options = { 0 => { 0 => [options[:available_options]].flatten.compact } }

    @selected_row = options[:ocr_row]
    @relate_model_rows = [options[:ocr_row]].flatten.compact

    @ccr_result_id_prefix = params[:ccr_result_id_prefix]
    @parent_ccr_result_id = params[:parent_ccr_result_id]
    @next_ccr_result_id = params[:next_ccr_result_id]

    respond_to do |format|
      format.html
      format.xml  { render :xml => @scr_row }
    end
  end

  def code_combined_reference_screen
    @screen_id = params[:screen_id]
    @selected_index = params[:selected_index].to_i
    parent_scr_row_id = params[:parent_scr_row_id].to_i
    @parent_scr_row = Row.find(parent_scr_row_id) if parent_scr_row_id > 0
    @scr_row = Row.find(params[:scr_row_id])

    sub_scr_row_id = params[:sub_scr_row_id].to_i
    @sub_scr_row = Row.find(sub_scr_row_id) if sub_scr_row_id > 0

    multiplier_row_id = params[:multiplier_row_id].to_i
    @multiplier_row = Row.find(multiplier_row_id) if multiplier_row_id > 0

    @field = Field.find(params[:field_id])
    @input_name = params[:input_name]
    @ccr_result_id_prefix = params[:ccr_result_id_prefix]
    @parent_ccr_result_id = params[:parent_ccr_result_id]
    @next_ccr_result_id = params[:next_ccr_result_id]
    @ccr_group_result_id = params[:ccr_group_result_id]

    @selected_values = params[:selected_options] || []
    @selected_values << params[:selected_value] unless params[:selected_value].to_s.strip.empty?
    options = @field.custom_field.options(@parent_scr_row || @scr_row, @field, @selected_values, true )

    @available_options = [options[:available_options]].flatten.compact

    respond_to do |format|
      format.html
      format.xml  { render :xml => @scr_row }
    end
  end

  def code_combined_reference_options
    @field = Field.find(params[:field_id])
    @scr_row = Row.find(params[:scr_row_id])
    
    selected_values = params[:selected_options] || []
    selected_values << params[:selected_value] unless params[:selected_value].to_s.strip.empty?
    options = @field.custom_field.options(@scr_row, @field, selected_values, false )
    
    @relate_model_rows = [options[:ocr_row]].flatten.compact
    @ccr_text = options[:ccr_text].to_s

    if CustomFields::CodeCombindedReference.field_display_as(@field.value) == :model_for_sale && !options[:ocr_row].nil?
      @relate_model_rows += CustomFields::OptionCombindedReference.related_model_rows(options[:ocr_row], selected_values.flatten, @field.source_field)
      @model_options = CustomFields::OptionCombindedReference.model_options(options[:ocr_row], selected_values.flatten, @field.source_field)

      option_rows = Row.find(:all, :conditions => { :rows => { :id => @model_options.keys } } )
      option_rows.each {|option_row| @model_options[option_row] = @model_options.delete(option_row.id) }
    end
  end

  def reference_attribute
    @field = Field.find(params[:field_id].to_i)
    source_field = Field.find(params[:source_field_id].to_i)
    row = Row.find(params[:row_id].to_i) if params[:row_id].to_i > 0
    if @field.is_a?(Fields::ReferenceAttribute) && !row.nil?
      if source_field.is_a?(Fields::Data)
        actual_row = Field.row_by_field(source_field, row)
        cell = actual_row.cell(source_field.custom_field_id) unless actual_row.nil?
        @result_value = cell.nil? ? '' : cell.to_html
      else
        @result_value = source_field.evaluate_value(row)
      end
    elsif @field.is_a?(Fields::CodeCombindedReferenceAttribute) && !row.nil?
      active_field = Field.find(params[:active_field_id].to_i) #ccr_field
      @selected_options = (params[:selected_options] || []).select{|id| !id.empty? }
      @selected_options << params[:selected_value] unless params[:selected_value].to_s.strip.empty?
      options = active_field.custom_field.options(row, active_field, @selected_options, false)
      relate_model_rows = [options[:ocr_row]].flatten.compact
      relate_model_rows += CustomFields::OptionCombindedReference.related_model_rows(options[:ocr_row], @selected_options.flatten, active_field.source_field) unless options[:ocr_row].nil?

      case source_field.custom_field
      when CustomFields::TextArea, CustomFields::TextField
        cast_method = 'to_s'
      when CustomFields::NumericField
        cast_method = 'to_f'
      else
        raise 'Missing implementation'
      end
      
      @result_value = (cast_method == 'to_s') ? '' : 0
      relate_model_rows.flatten.each do |r|
        @result_value << ' ' unless cast_method == 'to_f' || @result_value.empty?
        unless r.nil?
          actual_row = Field.row_by_field(source_field, r)
          cell = actual_row.cell(source_field.custom_field_id) unless actual_row.nil?
        end
        @result_value += cell.absolute_value.send(cast_method) unless cell.nil?
      end
    else
      @result_value = ''
    end
    respond_to do |format|
      format.html
      format.xml  { render :xml => @field }
    end
  end

  def parameter()
    @field = Field.find(params[:field_id].to_i)
    date_value = params[:date_value]

    @result_value = @field.custom_field.evaluate_value(date_value)
    respond_to do |format|
      format.html
      format.xml  { render :xml => @field }
    end
  end

  def save_full_log (action, seq_no, value = {}, created_date = nil)
    options = {
      :row_id => @row.id, 
      :action => action, 
      :user => User.find(session['user_id'])['login'],
      :seq_no => seq_no, :value => value
    }
    
    options[:created_at] = created_date unless created_date.nil?
    
    FullLog.new(options).save
  end

  def print
    #    @screen = session.active_screen
    @screen = Screen.find(params[:id])
    @row_ids = RowsController.get_session_row_ids(session.session_id, @screen.id, true)
    @action_source = 'print'

    @current_user = ApplicationController.current_user

    display_flag_label = Label.descr_by_name('G_List')
    @fields = []
    @screen.fields.each do |field|
      if field.display_in_screen?(display_flag_label)
        @fields << field
      end
    end

    #    options = Row.filter_by_custom_fields(params[:id].to_i, {}, 'index', false)
    #
    #    @row_ids = options[:filtered_row_ids]
    #    session[:sort_field_id_order] = options[:sort_field_id_order]
    #
    #    RowsController.store_session_row_ids(session.session_id, @screen.id, @row_ids)
    #
    @sort_field_id_order = session[:sort_field_id_order]
    #    @row_ids ||= []

    #     @row_count = @row_ids.size


    #    pageno_from = (rpp*(@pageno.to_i-1))
    #    pageno_to = ((rpp*@pageno.to_i)-1)
    #
    #    @maxpage = (@row_count.to_f / rpp).ceil

    #    @row_ids = @row_ids[pageno_from..pageno_to] || []

    @rows = @screen.rows.find(:all,
      :conditions => {
        :rows => { :id => @row_ids }
      }
    )

    @rows.sort!{|a, b| @row_ids.index(a.id) <=> @row_ids.index(b.id)}

    respond_to do |format|
      format.html # print.html.erb
      format.xml  { render :xml => @rows }
    end
  end

  def update_cell_calendar
    render :xml => params['detail_cell_value']
  end


  def model_look_up
    screen_id = params['screen_id']
    screen = Screen.find(screen_id)

    custom_field_ids = params['cf_id'] || {}
    custom_field_ids.each{|k, v|
      cf = CustomField.find(k)
      custom_field_ids[k] = case cf
      when CustomFields::Reference
        { 'row_id' => v }
      when CustomFields::CodeCombindedReference
        v
      else
        #~ ToDo: Map the rest of the CustomField type
        raise 'Missing implementation'
      end

    }
    options = Row.filter_by_custom_fields(screen_id, custom_field_ids, 'index', true)
    row_ids = options[:filtered_row_ids]

    case row_ids.size
    when 0
      result_message = "Item not found in '#{screen.label_descr}'"
    when 1
      row_id = row_ids.first
      cell_click = <<JAVASCRIPT
      $("#{params[:cell_id]}_post").click();
JAVASCRIPT
        
    else
      result_message = "Multiple items found in '#{screen.label_descr}' with the selected values. <i>Please contect TSE</i>"
    end

    ui_feedback = <<JAVASCRIPT
$("#{params[:cell_id]}_post").value = "#{row_id}";
$("#{params[:cell_id]}").value = "#{row_id}";
$("#{params[:div_id]}_result").innerHTML = "#{result_message}";
#{cell_click}
JAVASCRIPT
    
    url = nil
    
    update_ui_and_perform_next(ui_feedback, url)
  end

  private
  
  def import_execute_feedback(ajax_result_id, content_count, row_count, error_count, executed_at, notification = nil)
    if notification.is_a?(Exception)
      progress = " <span class='error_message'>#{notification.to_s.strip.gsub(/[\r\n]/, '<br />')}</span>"
      notification = ''
    else
      percentage = (content_count > 0) ? (row_count.to_f/ content_count) : 0.0
      estimated = (percentage > 0.0) ? time_ago_in_words(executed_at + ((Time.now - executed_at) / percentage)) : '...'
      percentage = (100 * percentage).floor
      progress = <<HTML_TAG
<table class='' style='' cellspacing='0'>
  <tr>
    <td class='td_cell' style='background-color: #008; width: #{(percentage)*2}px;'></td>
    <td class='td_cell' style='background-color: #888; width: #{(100-percentage)*2}px;'></td>
    <td style='font-size: smaller'>#{percentage}%</td>
  </tr>
</table>
HTML_TAG
      notification = <<HTML_TAG
<img src='/images/loading.gif'>&nbsp;#{notification || 'Importing...'}
<p>
<b>Note: </b>Do not close this page.
</p>
HTML_TAG
    end
    message = <<HTML_TAG
<table>
  <tr>
    <th class='th_row_header'>Imported:</th>
    <td>#{row_count - error_count} item(s)</td>
  </tr>
  <tr>
    <th class='th_row_header'>Failed:</th>
    <td>#{error_count} item(s)</td>
  </tr>
  <tr>
    <th class='th_row_header'>Progress:</th>
    <td>#{progress}</td>
  </tr>
  <tr>
    <th class='th_row_header'>Estimated:</th>
    <td>#{estimated}</td>
  </tr>
</table>
#{notification}
HTML_TAG

    <<JAVASCRIPT
$("#{ajax_result_id}").innerHTML = "#{message.to_s.gsub(/[\r\n]/, ' ').gsub(/"/, '\\"')}";
JAVASCRIPT
  end

  def change_type_of_value (custom_field, cell)
    output = []
    is_string = false

    case custom_field
    when CustomFields::LeftRight
    when CustomFields::IssueTracking
      cell.value.each do |key, value|
        output << "[#{key}]:#{value}" unless value == ''
      end
    when CustomFields::CheckBox
    when CustomFields::ComboBox
      is_string = true
    when CustomFields::RadioButton
      is_string = true
    else
      is_string = true
    end

    output = cell.to_text.split(', ') unless is_string || custom_field.is_a?(CustomFields::IssueTracking)

    is_string ? cell.to_text : output.empty? ? '' : output.sort! {|a, b| a <=> b}
  end
end