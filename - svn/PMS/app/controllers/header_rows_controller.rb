class HeaderRowsController < ApplicationController
  layout nil
  layout 'print', :only => [:print]
	protect_from_forgery :only => [:create]

  class << self
  end # class << self

  def screen_from_action(params)
    RowsController.screen_from_action(params) || super
  end
  
	# GET /rows
	# GET /rows.xml
	def index
    session[:search_filter_info] = {}
		@screen = Screen.find(params[:id])
    @action_source = params[:action_source] || 'index'
    @quick_operation = params[:quick_operation] || 'index'
    @filtered_reference = params[:filtered_reference] || {}
    @row_ids = []
    @row_pattern = Row.find(params[:row_pattern_id].to_i) unless params[:row_pattern_id].nil?

    rpp = ApplicationController.current_user.rows_per_page
    @pageno = (!@action_source.include?('page_')) ? 1 : params[:pageno].gsub('/','')

    case @action_source
    when 'index'
      options = @quick_operation == 'index' ? Row.filter_by_custom_fields(params[:id].to_i, {}, 'index', false) : {}

      @row_ids = options[:filtered_row_ids] || []
      @row_ids_wo_limit = options[:filtered_row_ids_wo_limit] || []
      @row_pattern = Row.find(options[:row_pattern_id]) unless options[:row_pattern_id].nil?
      session[:sort_field_id_order] = options[:sort_field_id_order] || []

      RowsController.store_session_row_ids(session.session_id, @screen.id, @row_ids, @row_ids_wo_limit)

    when 'search', 'page_search', 'page_index'

      session[:search_filter_info] = {}

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

    @sort_field_id_order = session[:sort_field_id_order]
    
    @row_ids ||= []

    @row_count = @row_ids.size

    #Page generator
    pageno_from = (rpp*(@pageno.to_i-1))
    pageno_to = ((rpp*@pageno.to_i)-1)

    @maxpage = (@row_ids.size.to_f / rpp).ceil
    @row_ids = @row_ids[pageno_from..pageno_to] || []

    @rows = @screen.rows.find(:all,
      :conditions => {
        :rows => { :id => @row_ids }
      }
    )

    @rows.sort!{|a, b| @row_ids.index(a.id) <=> @row_ids.index(b.id)}

    GC.start

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @rows }
    end
  end
	
  # GET /rows/1
  # GET /rows/1.xml
  def show
    @row = Row.find(params[:id])
		
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @row }
    end
  end
	
  # GET /rows/new
  # GET /rows/new.xml
  def new
    @screen = Screen.find(params[:id])
    @row = HeaderRow.new(:screen_id => @screen.id)
    @filtered_reference = params[:filtered_reference] || {}

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @row }
    end
  end
	
    # GET /rows/edit/1
    def edit
      @row = Row.find(params[:id])
      @filtered_reference = params[:filtered_reference] || {}
    end
	
    # GET /rows/edit/1
    def edit_unsave_row
      #
    end
	
    # POST /rows
    # POST /rows.xml
    def create
      @row = HeaderRow.save(params)

      respond_to do |format|
        format.html # create.html.erb
        format.xml  { render :xml => @row }
      end
    end

    # PUT /rows/1
    # PUT /rows/1.xml
    def update
      @row = Row.find(params[:id])
      respond_to do |format|
        if @row.update_attributes(:remark => params[:remark])
          @cells = params[:cells]
          @cells.each do |field_id,value|
            @cell = Cell.find(:first, :conditions => ['row_id = ? and field_id = ?', @row.id , field_id])
            if @cell == nil
              Cell.new(:row_id => @row.id, :field_id => field_id, :value => value).save
            else
              @cell.update_attributes(:row_id => @row.id, :field_id => field_id, :value => value)
            end
          end
          forward_to_front_desk :format => format, :object => @row, :screen_id =>@row.screen_id
        else
          back_to_operation_form :format => format, :action => 'edit', :object_errors =>  @row.errors
        end
      end
    end

    def export
      # redirect to report controller
      redirect_to :controller=> 'reports', :action => 'export', :id => params[:id], :filtered_row_ids => params[:filtered_row_ids], :action_source => params[:action_source], :parent_row_id => params[:parent_row_id]
    end

    def relations
      render :text => ''
    end
	
    def edit_header
      @row = Row.find(params[:id])
    end
	
    def new_header
      @screen = Screen.find(params[:id])
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





    def print
#     @screen = session.active_screen
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

      @sort_field_id_order = session[:sort_field_id_order]

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

    def relations
      render :text => 'hello world !!!'
    end
end
