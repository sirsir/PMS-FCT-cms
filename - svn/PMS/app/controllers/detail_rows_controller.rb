class DetailRowsController < ApplicationController
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
    detail_screen_id = params[:id].to_i
    @revision_row = RevisionRow.find(params[:row_id].to_i)
    @filtered_reference = params[:filtered_reference] || {}
    @action_source = params[:action_source] || 'index'
    @screen = DetailScreen.find(detail_screen_id)
    @sort_field_id_order = []

    case @action_source
    when 'index'
      @rows = DetailRow.find(:all,
        :conditions => {
          :rows => {:screen_id => @screen.id, :row_id => @revision_row.id}
        })
      @row_ids = @rows.collect{|r| r.id}
      RowsController.store_session_row_ids(session.session_id, @screen.id, @row_ids)
    when 'search', 'page_search', 'page_index'
      @row_ids = RowsController.get_session_row_ids(session.session_id, @screen.id)
    end
    @readonly = (@revision_row.id != @revision_row.header_row.latest_revision.id)

    @row_count = @row_ids.size

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
    @revision_row_id = params[:revision_row_id] # Romove '/' after header row number
    @screen = Screen.find(params[:id])
	  @filtered_reference = params[:filtered_reference] || {}
    
    @row = DetailRow.new(:screen_id => @screen.id, :row_id => @revision_row_id)
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @row }
    end
  end
  
  # GET /rows/edit/1
  def edit
    @row = Row.find(params[:id])
    @readonly = (@row.revision_row.id != @row.revision_row.header_row.latest_revision.id)
    @filtered_reference = params[:filtered_reference] || {}

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @row }
    end
  end
  
  # POST /rows
  # POST /rows.xml
  def create
    revision_row = RevisionRow.find(params[:revision_row_id].to_i)
    detail_screen = DetailScreen.find(params[:screen_id].to_i)

    @detail_row = DetailRow.new()
    @detail_row.revision_row = revision_row
    @detail_row.screen = detail_screen
    @detail_row.remark = params.delete(:remark)
    @form_content_reuse = params[:form_content_reuse]
    @save_as_new_copy = (params[:save_as_new_copy] =~ /true/i)

    cells = params.delete(:cells) || {}

    cells.each do |field_id, value|
      cell = Cell.new(:field_id => field_id, :value => value)
      @detail_row.cells << cell
      @detail_row.load_cell_hash(cell)
    end

    ActiveRecord::Base.transaction do
      @detail_row.cells.each do |c|
        case c.field
        when CustomFields::AutoNumbering
          CustomFields::AutoNumbering.set_cell_temp_text(c.value)
        end
      end

      if @detail_row.save && @detail_row.cells.all? {|c| c.save }
        #~ Do Nothing
      end
      
      raise ActiveRecord::Rollback unless @detail_row.errors.empty?

      @detail_row.cells.each do |c|
        case c.field
        when CustomFields::AutoNumbering
          auto_numbering_text = CustomFields::AutoNumbering.increase(c.field_id, @detail_row.cells)
          CustomFields::AutoNumbering.set_cell_text(c.value, auto_numbering_text)
          c.save
        end
      end


    end

    revision_row.clear_cache(:clear_details => false)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @rows }
    end unless @save_as_new_copy
  end
 
  # PUT /rows/1
  # PUT /rows/1.xml
  def update
    @detail_row = DetailRow.find(params[:row][:id])
    
    @save_as_new_copy = (params[:save_as_new_copy] =~ /true/i)

    if @save_as_new_copy
      params[:screen_id] = @detail_row.screen_id
      params[:revision_row_id] = @detail_row.revision_row_id
      params[:cells_org] = params[:cells]
      params[:remark_org] = params[:remark]

      self.create

      params[:cells] = params[:cells_org]
      params[:remark] = params[:remark_org]
    end

    cells = params.delete(:cells) || {}

   #~ Create cells for new fields
    custom_field_ids = cells.collect{|field_id, value| field_id.to_i }
    current_custom_field_ids = @detail_row.cells.collect{|c| c.field_id }.uniq
    new_custom_field_ids = custom_field_ids - current_custom_field_ids

    new_custom_field_ids.each do |cf_id|
      cell = Cell.new(:field_id => cf_id, :value => nil)
      @detail_row.cells << cell
      @detail_row.load_cell_hash(cell)
    end
    #~ Update existing cells, and clear missing values
    @detail_row.screen.fields.each do |f|
      unless f.custom_field.nil?
        cell = @detail_row.cell(f.custom_field_id)
        cell.value = cells.delete(cell.custom_field_id.to_s)
      end
    end

    @detail_row.remark = params.delete(:remark)
    if @detail_row.save
      #~ Save the cells
      @detail_row.cells.each do |c|
        c.save
      end
    end
    
    if @save_as_new_copy
      render :action => 'create'
    else
      respond_to do |format|
        format.html # create.html.erb
        format.xml  { render :xml => @detail_row }
      end
    end
  end
  

  def export
    # redirect to report controller
    redirect_to :controller=> 'reports', :action => 'export', :id => params[:id], :filtered_row_ids => params[:filtered_row_ids], :action_source => params[:action_source], :parent_row_id => params[:parent_row_id]
  end

  def import
    # redirect to row controller
    redirect_to :controller=> 'rows', :action => 'import', :id => params[:id],
      :parent_row_id => params[:parent_row_id], :operation_area_id => params[:operation_area_id]
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
 end