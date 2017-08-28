class UsersController < ApplicationController
  layout nil

  def screen_from_action(params)
    Screen.from_action(
      :controller => params['controller'],
      :action => 'index'
    )
  end
  
  # GET /users
  # GET /users.xml
  def index
    @screen = session.active_screen
    @users = User.find(:all, :conditions => ['login <> ? ', 'tsestaff' ], :include_disabled => true)
    @users = @users.sort_by{|a| [a.disabled_flag ? 1 : 0, a.description.downcase] }

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    @screen = session.active_screen
    @user = User.find(params[:user_id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/fetch_row/1
  # GET /users/fetch_row/1.xml
  def fetch_row
    @screen_self = session.active_screen
    
    @user = User.find(params[:user_id])

    respond_to do |format|
      format.html # fetch_row.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @screen = session.active_screen
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/1/edit
  def edit
    @screen = session.active_screen
    @from_user_info = params[:user_id].nil?
    @user = User.find( @from_user_info ? session['user_id'] : params[:user_id] )
  end

  # POST /users
  # POST /users.xml
  def create
    @screen = session.active_screen
    @form_content_reuse = params[:form_content_reuse]
    
    params[:user]['disabled_flag'] = CustomFields::CheckBox.true_or_false?(params[:user]['disabled_flag']).to_s
    
    @user = User.new(params[:user])
    
    @user.save
    
    respond_to do |format|
      format.html # create.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update 
    @screen = session.active_screen
    @form_content_reuse = params[:form_content_reuse]
    
    @user = User.find(params[:user_id])
    
    if @user.login =~ /tsestaff/
      @user.errors.add @user.login, 'cannot be modified'
    else
      @from_user_info = params[:from_user_info]

      params[:user]['disabled_flag'] = CustomFields::CheckBox.true_or_false?(params[:user]['disabled_flag']).to_s

      @user.update_attributes(params[:user])
    end

    respond_to do |format|
      format.html # update.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    render :text => 'Pending on CaseCade Delete for users'

    @screen = session.active_screen
    
    @user = User.find(params[:user_id])
    @user.destroy

    respond_to do |format|
      forward_to_front_desk :format => format, :object => @user, :action => 'index'
    end
  end
  
  def search 
    render :text => (RAILS_ENV =~ /development/) ? '<span class="missing_implementation">Implement how to display the search controls.</span>' : ''  
  end
   
end
