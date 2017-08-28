class CustomFieldsController < ApplicationController
    layout nil 
	
  protect_from_forgery :only => [:create, :delete, :update]

  def permission_map(action)
    'index'
  end

  # GET /custom_fields
  # GET /custom_fields.xml
  def index
    @screen = session.active_screen
    @custom_fields = CustomField.find(:all).sort_by{|cf| [cf.class.to_s, cf.name] }
    @max_level = @custom_fields.collect {|cf| cf.level}.max
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @custom_fields }
    end
  end

  # GET /custom_fields/fetch_row/1
  # GET /custom_fields/fetch_row/1.xml
  def fetch_row
    @screen = session.active_screen

    @custom_field = CustomField.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @custom_field }
    end
  end

  # GET /custom_fields/new
  # GET /custom_fields/new.xml
  def new
    @screen = session.active_screen
    @custom_field_type = params[:custom_field_type]

    if @custom_field_type.nil?
      @custom_field_types = CustomField.types.sort_by{|cf| cf.class.name }
    else
      custom_field_model = @custom_field_type.constantize
      @custom_field = custom_field_model.new( :name => custom_field_model.default_name)
      @custom_fields = CustomField.find(:all).sort_by{|cf| cf.name }
      @labels = Label.find(:all).sort_by{|l| l.descr }
      @screens = Screen.find(:all).select{|s| !s.system? and !s.is_a?(MenuGroupScreen) }.sort_by{|s| s.label_descr }

      @assigned_screens = []
      @assigned_option_screens = []
      @assigned_options = []
      
      case @custom_field
      when CustomFields::StockQuantity
        @stocks = Stock.find(:all)
      end
    end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @custom_field }
    end
  end

# GET /custom_fields/1/edit
  def edit
    @screen = session.active_screen

    @custom_field = CustomField.find(params[:id])
    @custom_fields = CustomField.find(:all).sort_by{|cf| cf.name }
    @labels = Label.find(:all).sort_by{|l| l.descr }
    @screens = Screen.find(:all, :conditions => ['system = ?', 0]).sort_by{|s| s.label_descr }

    if (@custom_field.value.to_s.include? 'label_ids')
      @assigned_options = @custom_field.labels
    else     
      case @custom_field
      when CustomFields::ScreenCombindedReference
        @assigned_screens = @custom_field.screens
        @assigned_option_screens = @custom_field.option_screens
      when CustomFields::CodeCombindedReference
        @assigned_options = @custom_field.separator
      when CustomFields::StockQuantity
        @stocks = Stock.find(:all)
      end
    end

    respond_to do |format|
      format.html # edit.html.erb
      format.xml  { render :xml => @custom_field }
    end
  end

  # POST /custom_fields
  # POST /custom_fields.xml
  def create
    @screen = session.active_screen
    @form_content_reuse = params[:form_content_reuse]

    @custom_field = params['custom_field_type'].constantize.new(params[:custom_field])

    @custom_field.save
  end

  # PUT /custom_fields/1
  # PUT /custom_fields/1.xml
  def update
    @screen = session.active_screen
    @form_content_reuse = params[:form_content_reuse]
    
    @custom_field = CustomField.find(params[:id])
    
    @custom_field.update_attributes(params[:custom_field])
  end

  # DELETE /custom_fields/1
  # DELETE /custom_fields/1.xml
  def destroy
    @custom_field = CustomField.find(params[:id])
    
    ActiveRecord::Base.transaction do
      @custom_field.destroy
    end
  end

  def parameter
    @screen = Screen.find(params[:screen_id])

    respond_to do |format|
		  format.html # index.html.erb
		  format.xml  { render :xml => @screen }
    end
  end

  def left_right_default_value
    @left_right_rows = Screen.find(params[:screen_id]).rows
    
    respond_to do |format|
		  format.html # index.html.erb
		  format.xml  { render :xml => @screen }
    end
  end
    
  def search 
    render :text => (RAILS_ENV =~ /development/) ? '<span class="missing_implementation">Implement how to display the search controls.</span>' : ''  
  end
end

