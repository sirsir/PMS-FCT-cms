class LabelsController < ApplicationController
  layout nil

  def permission_map(action)
    'index'
  end

  # GET /labels
  # GET /labels.xml
  def index
   redirect_to :controller=> 'captions', :action => 'index'
  end

  # GET /labels/1
  # GET /labels/1.xml
  def show
    @label = Label.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @label }
    end
  end

  # GET /labels/new
  # GET /labels/new.xml
  def new
    @label = Label.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @label }
    end
  end

  # GET /labels/1/edit
  def edit
    @label = Label.find(params[:id])
  end

  # POST /labels
  # POST /labels.xml
  def create
    @label = Label.new(params[:label])

    respond_to do |format|
      if @label.save
        forward_to_front_desk :format => format, :object => @label, :action=>'index'
      else  
        back_to_operation_form :format => format, :action => 'new', :object_errors =>  @label.errors
      end
    end
  end

  # PUT /labels/1
  # PUT /labels/1.xml
  def update
    @label = Label.find(params[:id])

    respond_to do |format|
      if @label.update_attributes(params[:label])
        forward_to_front_desk :format => format, :object => @label, :action=>'index'
      else
        back_to_operation_form :format => format, :action => 'edit', :object_errors =>  @label.errors
      end
    end
  end

  # DELETE /labels/1
  # DELETE /labels/1.xml
  def destroy
    @label = Label.find(params[:id])
    @label.destroy

		respond_to do |format|
			forward_to_front_desk :format => format, :object => @label, :action=>'index'
		end
  end
  
  def search 
    render :text => (RAILS_ENV =~ /development/) ? '<span class="missing_implementation">Implement how to display the search controls.</span>' : ''
  end
   
end

