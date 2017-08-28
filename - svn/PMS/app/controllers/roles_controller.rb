class RolesController < ApplicationController
  layout nil

  def screen_from_action(params)
    Screen.from_action(
      :controller => params['controller'],
      :action => 'index'
    )
  end

  # GET /roles
  # GET /roles.xml
  def index
    @screen = session.active_screen
    @roles = Role.find(:all).sort_by{|r| r.name }

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @roles }
    end
  end

  # GET /roles/1
  # GET /roles/1.xml
  def show
    @screen = session.active_screen
    @role = Role.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @role }
    end
  end

  # GET /fields/fetch_row/1
  # GET /fields/fetch_row/1.xml
  def fetch_row
    @screen = session.active_screen
    
    @role = Role.find(params[:id])

    respond_to do |format|
      format.html # fetch_row.html.erb
      format.xml  { render :xml => @role }
    end
  end

  # GET /roles/new
  # GET /roles/new.xml
  def new
    @screen = session.active_screen
    @role = Role.new
    @all_users = User.find_active_users

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @role }
    end
  end

  # GET /roles/1/edit
  def edit
    @screen = session.active_screen
    @role = Role.find(params[:id])
    @all_users = User.find_active_users
  end

  # POST /roles
  # POST /roles.xml
  def create
    @screen = session.active_screen
    @form_content_reuse = params[:form_content_reuse]

    user_ids = params[:role][:user_ids]
    params[:role].delete(:user_ids) unless params[:role][:user_ids].nil?
    @role = Role.new(params[:role])       

    if @role.save
      @role.users = User.find(user_ids) unless user_ids.nil?
      @role.users.each{|u| u.update_attributes( :updated_at => Time.now ) }
    end
    
    respond_to do |format|
      format.html # create.html.erb
      format.xml  { render :xml => @role }
    end
  end

  # PUT /roles/1
  # PUT /roles/1.xml
  def update
    @screen = session.active_screen
    @form_content_reuse = params[:form_content_reuse]
    
    @role = Role.find(params[:id]) 
    @role.user_ids.each{|u_id| User.find(u_id).update_attributes( :updated_at => Time.now ) }
    @role.users.clear
    @role.users = User.find(params[:role][:user_ids]) unless params[:role][:user_ids].nil?
    @role.user_ids.each{|u_id| User.find(u_id).update_attributes( :updated_at => Time.now ) }
    
    @role.update_attributes(params[:role])

    respond_to do |format|
      format.html # create.html.erb
      format.xml  { render :xml => @role }
    end
  end

  # DELETE /roles/1
  # DELETE /roles/1.xml
  def destroy
    @screen = session.active_screen
    
    @role = Role.find(params[:id])

    ActiveRecord::Base.transaction do
      @role.destroy
    end
  end
    
  def search 
    render :text => (RAILS_ENV =~ /development/) ? '<span class="missing_implementation">Implement how to display the search controls.</span>' : ''  
  end
  
end
