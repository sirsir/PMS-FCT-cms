class LanguagesController < ApplicationController
  layout nil

  def permission_map(action)
    'index'
  end

  # GET /languages
  # GET /languages.xml
  def index
    @screen = session.active_screen
    @languages = Language.find(:all)
    @screen = Screen.find(params[:id])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @languages }
    end
  end

  # GET /languages/fetch_row/1
  # GET /languages/fetch_row/1.xml
  def fetch_row
    @screen = session.active_screen
    @language = Language.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @language }
    end
  end

  # GET /languages/new
  # GET /languages/new.xml
  def new
    @screen = session.active_screen
    @language = Language.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @language }
    end
  end

  # GET /languages/1/edit
  def edit
    @screen = session.active_screen
    @language = Language.find(params[:id])
  end
  
  def load_form_options
    @screen = session.active_screen

    @caption = Caption.find(:all , :conditions => ['language_id = ? ', params[:id]] )
  end

  # POST /languages
  # POST /languages.xml
  def create
    @screen = session.active_screen
    @form_content_reuse = params[:form_content_reuse]
    
    @language = Language.new(params[:language])
    @language.save
  end

  # PUT /languages/1
  # PUT /languages/1.xml
  def update
    @screen = session.active_screen
    @form_content_reuse = params[:form_content_reuse]

    @language = Language.find(params[:id])
    @language.update_attributes(params[:language])

    respond_to do |format|
      format.html # update.html.erb
      format.xml  { render :xml => @language }
    end
  end

  # DELETE /languages/1
  # DELETE /languages/1.xml
  def destroy
    @language = Language.find(params[:id])
    
    ActiveRecord::Base.transaction do
      @language.destroy
    end
  end
  
  def search 
    render :text => (RAILS_ENV =~ /development/) ? '<span class="missing_implementation">Implement how to display the search controls.</span>' : ''  
  end
   
end
