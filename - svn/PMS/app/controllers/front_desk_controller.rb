require 'webrick'

class FrontDeskController < ApplicationController
  #ssl_required :login, :index, :welcome
  layout 'standard-layout', :except => ['welcome', 'index', 'offline', 'print']

  helper 'front_desk' 
  helper_method :get_child ,:get_parent
  helper_attr :parents,:myroots,:access
  attr_accessor :parents,:myroots,:access


  def permission_mapping
    {
      'welcome' => 'index',
      'index' => 'index',
      'temp_form' => 'index'
    }
  end

  def offline

  end

  # Extracts the action_name from the request parameters and performs that action.
  def process(request, response, method = :perform_action, *arguments) #:nodoc:
    if Rails.configuration.valid_database?
      super(request, response, method, *arguments)
    else
      response.request = request

      initialize_template_class(response)

      @_request, @_params, @_cookies = request, request.parameters, request.cookies

      @_response         = response

      response.body = Rails.configuration.database_setting

      send_response
    end
  end
  
  # Call http://localhost:3000/front_desk/init?password=xxxxxx to create the tsestaff user
  def init
    user = User.create_tsestaff(params[:password], params[:language_id])

    if user.errors.empty?
      redirect_to :action => 'login'
    else
      render :text => user.errors.full_messages.inspect
    end
  end

  def login
    case request.method
    when :post
      user = User.authenticate(params['user_login'], params['user_password'])

      session['user_id'] = user ? user.id : nil
      
      if session['user_id']
        flash['notice']  = 'Login successful'
        redirect_to(:action => 'index')
      else
        @login    = params['user_login']
        @message  = 'Login unsuccessful'
      end
    when :get
      if ApplicationController.bypass_authorize?(params)
        ApplicationController.enter_admin_mode
        
        session['user_id'] = ApplicationController.current_user.id

        if session['user_id']
          render :text => 'Login successful'
        end
      end
    end
  end
  
  def logout
    session_obj = Session.find(:first, :conditions => ['session_id = ?' , session.session_id])
    session_obj.rows.clear if session_obj
      
    session['user_id'] = nil
	  redirect_to(:action => 'login')
  end  
    
  def index
    @@validate_cache_env ||= validate_cache_env
    
    port = get_next_port(request.port)
    @base_url = "#{request.protocol}#{request.host}:#{port}"
  end

  def validate_cache_env
    msg = ApplicationController.validate_cache_env(:html)
    
    render :text => msg unless msg.empty? || Rails.configuration.offline

    msg
  end
  
  def get_next_port(base_port)
    conf = Rails.configuration

    @@listening_ports ||= (conf.first_port.to_i..(conf.first_port.to_i + conf.listening_ports.to_i - 1)).to_a

    #~ Extract the reserved ports
    #    @@reserved_ports ||= nil
    #
    #    if @@reserved_ports.nil?
    #      reserved_port_indexes = @@listening_ports.length > 1 ? conf.reserved_ports.values.collect{|i| i.to_i} : []
    #      @@reserved_ports = reserved_port_indexes.collect{|i| @@listening_ports[i]}
    #      @@listening_ports -= @@reserved_ports
    #    end
    
    @@port ||= base_port
    @@port = (@@listening_ports.last == @@port) ? @@listening_ports.first : @@listening_ports[@@listening_ports.index(@@port).to_i+1]

    if @@port.nil?
      render :text => <<HTML_TAG
Unable to navigate to a listening port...
<pre>
Running Port   : #{base_port}
Config  Port(s): #{@@listening_ports.inspect.gsub(/[\[\]]/, '')}
</pre>
HTML_TAG
    elsif @@port == base_port
      return @@port
    end
    
    
    begin
      s = WEBrick::HTTPServer.new(
        :Port            => @@port,
        :DocumentRoot    => "#{RAILS_ROOT}/log"
      )

      s.shutdown

      return get_next_port(base_port)
    rescue Exception => e
      return @@port
    end
  end
    
  def welcome
    @root_screen = Screen.find(:first, :conditions => ['name = ?' , 'root'])
    @max_level = Screen.find(:all).collect {|s| s.level}.max
    if params[:screen].nil?
      @screen= nil
	  else
      @screen = YAML::load(params[:screen])
      @row_id = params[:row_id]
      @action_type = params[:action_type]
      @error_msg = params[:error_msg]
      @action_source = params[:action_source] || ''
      @pageno = params[:pageno] || '1'
	  end

    render  :layout => 'frontDesk-layout'
  end
  
  def access(screen)
    if ApplicationController.admin_mode?
      return true
    elsif (screen.id == 1) # setting_menu only for tsestaff
      return false
    elsif screen.allow_action?('index')
      return true
    else
      return false
    end
  end

  def ping
    render :text => request.env['SERVER_SOFTWARE']
  end

  def temp_form
    
  end
end
