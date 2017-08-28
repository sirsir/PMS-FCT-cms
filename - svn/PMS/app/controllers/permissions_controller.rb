class PermissionsController < ApplicationController
  layout nil

  # GET /permissions
  # GET /permissions.xml

  def permission_mapping
    super.merge(
      {
        'index_role_screen' => 'index',
        'index_role_field' => 'index',
        'index_user_screen' => 'index',
        'index_user_field' => 'index',
        'fetch_row' => 'index'
      }
    )
  end
  
  def screen_from_action(params)
    permission_type_key = (params.keys & ['type', 'permission_type']).first
    if permission_type_key && params[permission_type_key] =~ /^Permissions::/
      permission_type = params[permission_type_key].constantize
      action = "index_#{permission_type.name.to_s.gsub('Permissions::','').underscore}"
    else
      action = params[:action]
    end
    
    if action =~ /fetch_row/
       screen_id = params[:id].split(/_/).first
       Screen.find(screen_id)
    else
      Screen.from_action(
        :controller=>'permissions',
        :action=>action
      )
    end
  end

  def index
    @permission_type = params[:permission_type].constantize
    @action_source = "index_#{@permission_type.name.to_s.gsub('Permissions::','').underscore}"
    
    @screen = session.active_screen
    @permissions = @permission_type.find(:all)
    @source_screen_id = params[:source_screen_id]

    if @permission_type == Permissions::RoleScreen or
        @permission_type == Permissions::RoleField
      @roles  = Role.find(:all)
    else
      @users  = User.find_active_users
    end
 
    @field_permission = @permission_type == Permissions::RoleField || @permission_type == Permissions::UserField
    @field_details = params.has_key?(:screen_id) and @field_permission
    @screen_id =  @field_permission ? params[:screen_id] : -1
    if @field_details
        @fields = Screen.find(params[:screen_id].to_i).fields
    elsif @field_permission 
        @screen = Screen.from_action(:controller=>'screens', :action=>'index')
        @screens  = Screen.find_by_dynamic
    else
        @screens  = Screen.permissionable
    end

    @roles.sort!{|a,b| a.name <=> b.name} if @roles
    @fields.sort!{|a,b| a.descr <=> b.descr} if @fields
    @screens.sort!{|a,b| a.label_descr <=> b.label_descr} if @screens

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @permissions }
    end
  end

  # GET /permissions/1
  # GET /permissions/1.xml
  def show
    @permission = Permission.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @permission }
    end
  end

  # GET /permissions/fetch_row/1
  # GET /permissions/fetch_row/1.xml
  def fetch_row
    screen_id = params[:id].split(/_/).first
    permission_id = params[:id].split(/_/).last

    @partial = params[:partial]
    @permission_type = params[:type].constantize
    
    @screen = Screen.find(screen_id)
    @field_permission = (@partial =~ /screen/).nil?
    if @field_permission
      @permission = Field.find(permission_id)
    else
      @permission = Screen.find(permission_id)
    end

    if @permission_type == Permissions::RoleScreen or
        @permission_type == Permissions::RoleField
      @roles  = Role.find(:all)
    else
      @users  = User.find_active_users
    end

    @roles.sort!{|a,b| a.name <=> b.name} if @roles

    respond_to do |format|
      format.html # fetch_row.html.erb
      format.xml  { render :xml => @permission }
    end
  end
  
  # GET /permissions/new
  # GET /permissions/new.xml
  def new
    @screen = session.active_screen
    @permission = Permission.new

    @permission_type = params[:type].constantize
    if @permission_type == Permissions::RoleScreen 
      @permission[:role_id] = params[:role_id]
      @permission[:screen_id] = params[:screen_id]
      @all_actions = Permission.action_options[:screen]
      @screen_id  = -1
    elsif @permission_type == Permissions::RoleField
      @permission[:role_id] = params[:role_id]
      @permission[:field_id] = params[:field_id]
      @all_actions = Permission.action_options[:field]
      @screen_id  = params[:field_screen_id]
      @source_screen_id = params[:source_screen_id]
    elsif @permission_type == Permissions::UserScreen
      @permission[:user_id] = params[:user_id]
      @permission[:screen_id] = params[:screen_id]
      @all_actions = Permission.action_options[:screen]
      @screen_id  = -1
    elsif @permission_type == Permissions::UserField
      @permission[:user_id] = params[:user_id]
      @permission[:field_id] = params[:field_id]
      @all_actions = Permission.action_options[:field]
      @screen_id  = params[:field_screen_id]
      @source_screen_id = params[:source_screen_id]
    end

    @grant_actions = []
    @revoke_actions = []
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @permission }
    end
  end

  # GET /permissions/1/edit
  def edit
    @screen = session.active_screen

    @permission = Permission.find(params[:id])
    @grant_actions = @permission.actions.nil? ? [] : @permission.actions[:grant] || []
    @revoke_actions = @permission.actions.nil? ? [] : @permission.actions[:revoke] || []
    @permission_type =  @permission.class.to_s.constantize
    @screen_id  = -1
    if @permission_type == Permissions::RoleScreen or
        @permission_type == Permissions::UserScreen
      @all_actions = Permission.action_options[:screen]
    else
      @all_actions = Permission.action_options[:field]
    end
  end

  # POST /permissions
  # POST /permissions.xml
  def create
    @screen = session.active_screen

    params[:permission][:actions] = nil if params[:permission][:actions].nil?
    
    permission_type = params[:permission_type].to_s
    permission_attributes = params[:permission] || {}
    screen_id = params[:screen_id].to_i
    
    @permissions = Permission.create_permissions(permission_type, permission_attributes, screen_id)
    @permission = @permissions.last

    respond_to do |format|
      format.html # create.html.erb
      format.xml  { render :xml => @permission }
    end
  end

  # PUT /permissions/1
  # PUT /permissions/1.xml
  def update
    @screen = session.active_screen
    
    @permission = params[:permission_type].constantize.find(params[:id])
    params[:permission][:actions] = nil if params[:permission][:actions].nil?
    @permission.update_attributes(params[:permission])
    @permissions = [@permission]
    
    respond_to do |format|
      format.html # update.html.erb
      format.xml  { render :xml => @permission }
    end
  end

  def index_role_screen
    redirect_to :action => 'index',
                :permission_type => Permissions::RoleScreen.to_s
  end

  def index_role_field
    redirect_to :action => 'index',
                :permission_type => Permissions::RoleField.to_s,
                :screen_id => params[:screen_id],
                :source_screen_id => params[:source_screen_id]
  end

  def index_user_screen
    redirect_to :action => 'index',
                :permission_type => Permissions::UserScreen.to_s
  end

  def index_user_field
    redirect_to :action => 'index',
                :permission_type => Permissions::UserField.to_s,
                :screen_id => params[:screen_id],
                :source_screen_id => params[:source_screen_id]
  end

  def search 
    render :text => (RAILS_ENV =~ /development/) ? '<span class="missing_implementation">Implement how to display the search controls.</span>' : ''  
  end
  
end
