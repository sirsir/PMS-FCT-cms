# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'ipaddr'

class ApplicationController < ActionController::Base
  # include SslRequirement
  # ssl_required :index, :new, :edit, :create, :update, :destroy, :export, :quick_add

  helper :all # include all helpers, all the time  

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery :secret => Rails.configuration.client_name
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like 'password').
  filter_parameter_logging :password, :authentication

  before_filter :firewall
  before_filter :set_current_request
  before_filter :authorize,:except =>[:init, :login, :logout, :offline]
  before_filter :set_session_screen, :except =>[:init, :login, :logout, :offline]
  before_filter :check_access_permission, :except =>[:init, :login, :logout, :offline]

  before_filter :load_form_options, :only =>[:new, :edit, :search]
  before_filter :set_charset
  before_filter :set_cache_buster, :except =>[:init, :login, :logout, :offline, :welcome, :temp_form]
  before_filter :set_flash_message

  before_filter :client_env_load_files
  
  after_filter :mem_stat, :only =>[:welcome]
  
  #   before_filter :login_requried

  class << self
    def admin_mode?
      current_user == admin_user
    end

    def enter_admin_mode(validate_cache = true)
      msg = validate_cache_env(:text) if validate_cache
      raise msg unless msg.to_s.empty?
      @@user = admin_user
    end

    def admin_sha
      @@admin_sha ||= Digest::SHA1.hexdigest("#{Rails.configuration.client_code}--#{Time.now.yday}--#{Time.now.year}--")
    end
    
    def current_user
      @@user if defined?(@@user)
    end

    def bypass_authorize?(params)
      params['authentication_token'] == ApplicationController.admin_sha && current_request.host == 'localhost'
    end

    def current_request=(value)
      @@request = value
    end

    def current_request
      @@request
    end

    def validate_cache_env(format = :html)
      screens = Screen.find(:all).select{|s| !s.system? && !s.is_a?(MenuGroupScreen) }
      screen_cache = screens.collect do |s|
        vm = VirtualMemory.load(:screen_index, s.id)

        if vm[:env] != Rails.env
          exec = "<a href='/screens/rebuild_index/#{s.id}'>Exec</a>"
          "Screen '#{s.name}'[#{s.id}] => '#{vm[:env]}' [#{exec}]"
        end
      end.compact

      custom_fields = CustomField.find(:all)
      custom_field_cache = custom_fields.collect do |cf|
        if cf.respond_to?(:rebuild_index)
          screens = cf.fields.collect{|f| f.screen }

          screens.collect do |s|
            vm_id = "#{cf.id}_#{s.id}"

            vm = VirtualMemory.load(:custom_field_index, vm_id)

            "CustomField #{cf.name}[#{cf.id}], for screen '#{s.name}'[#{s.id}] => '#{vm[:env]}'" if vm[:env] != Rails.env
          end
        end
      end.flatten.compact

      msg = ''
      unless screen_cache.empty? && custom_field_cache.empty?
        rake_screen = "rake db:screen:rebuild_index RAILS_ENV=#{Rails.env}"
        rake_custom_field = "rake db:custom_field:rebuild_index RAILS_ENV=#{Rails.env}"
	
        msg << <<HTML_TAG
#{'<p>' if format == :html }
Cache Environment miss matched. Please run Rake rebuild_index tasks.
#{'</p>' if format == :html }
#{'<pre>' if format == :html }
#{rake_screen unless screen_cache.empty? }
#{rake_custom_field unless custom_field_cache.empty? }

#{screen_cache.to_yaml unless screen_cache.empty? }
#{custom_field_cache.to_yaml unless custom_field_cache.empty? }
#{'</pre>' if format == :html }
HTML_TAG
      end

      msg
    end

    def os_platform
      RUBY_PLATFORM =~ /\w+\-(mswin32|mingw32)/ ? :mswin32 : :linux
    end
    
    private

    def admin_user
      @@admin_user ||= User.find(:first, :conditions => { :users => { :login => admin_login } } )
    end

    def admin_login
      'tsestaff'
    end

  end
  
  private

  def firewall
    @@config_firewall ||= begin
      config_firewall = [Rails.configuration.firewall, '127.0.0.1'].flatten.sort
      config_firewall.uniq!
      
      config_firewall.collect{|fw| IPAddr.new(fw) }
    end

    return if session['user_id'] || @@config_firewall.size == 1

    ip = IPAddr.new(request.env['REMOTE_ADDR'])

    unless @@config_firewall.any?{|fw| fw.include?(ip) }
      reason = 'Blocked by PMS firewall'
      render :text => "<span class='error_message' href='#{request.url}'>Access Denied</span><!-- #{reason} -->", :status => 403
    end
  end
  
  def set_current_request
    ApplicationController.current_request = request
  end
  
  def set_cache_buster
    response.headers['Cache-Control'] = 'no-cache, no-store, max-age=0, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = 'Fri, 01 Jan 1990 00:00:00 GMT'
  end
  
  def set_flash_message
    params[:flash] ||= {}

    params[:flash].each{|f, m| flash[f.to_sym] = m }
  end

  def set_charset
    # WIN32OLE.codepage = WIN32OLE::CP_UTF8
  end

  def authorize
    if Rails.configuration.offline
      redirect_to(:controller => 'front_desk', :action => 'offline', :status => 503)
    elsif ApplicationController.bypass_authorize?(params)
      ApplicationController.enter_admin_mode
      session['user_id'] = @@user.id
    elsif session['user_id'].nil?
      redirect_to_login
    elsif !defined?(@@user) || @@user.nil? || @@user.id != session['user_id']
      if User.exists?(session['user_id'])
        @@user = User.find(session['user_id'])
      else
        redirect_to_login
      end
    end
  end
  
  def redirect_to_login
    Session.purge

    session.delete
    redirect_to(:controller => 'front_desk', :action => 'login', :status => 302 )
  end

  def permission_mapping
    {
      'search' => 'index',
      'print' => 'index',
      'show' => 'index',
      'fetch_row' => 'index',
      'update' => 'edit',
      'create' => 'new'
    }
  end

  def permission_map(action)
    @permission_map ||= permission_mapping
    @permission_map[action] || action
  end

  def screen_from_action(params)
    Screen.from_action(
      :controller => params['controller'],
      :action => permission_map(params['action'])
    )
  end

  def set_session_screen
    @@screens_loaded ||= Screen.count > 0
    
    render :text => "<span class='error_message' href='#{request.url}'>Screens not loaded...</span>", :status => 500 unless @@screens_loaded

    screen = screen_from_action(params)
    
    if screen && (session.active_screen.nil? || session.active_screen.id != screen.id)
      session.active_screen = screen
    elsif screen.nil?
      session.active_screen = nil
    end
  end
  
  def check_access_permission
    action = permission_map(@action_name)

    unless !session.active_screen.nil? && session.active_screen.allow_action?(action)
      reason = session.active_screen.nil? ? 'No Screen selected' : "Action: '#{session.active_screen.name}[#{session.active_screen.id}]'.'#{action}', User:'#{ApplicationController.current_user.login}'"
      render :text => "<span class='error_message' href='#{request.url}'>Access Denied</span><!-- #{reason} -->", :status => 401
    end
  end

  def update_ui_and_perform_next(ui_feedback, next_action = nil)
    render(:update) do |page|
      page << ui_feedback
      page << "new Ajax.Request('#{next_action}', {asynchronous:true, evalScripts:true});" if next_action
    end
  end
  
  def load_form_options
  end
  
  def forward_to_front_desk(options={})
    # Store the mandetory options
    format = options[:format]
    object = options[:object]
    action = options[:action]
    controller = options[:controller] || controller_name
    screen_id = options[:screen_id]
    screen = options[:screen]
    row_id = options[:row_id] ||=0
    action_type = options[:action_type] ||= ''
    error_msg = options[:error_msg] ||= ''
    action_source = options[:action_source] ||= ''
    pageno = options[:pageno] ||= '1'
    
    screen = Screen.from_action( :action => action, :controller => controller, :screen_id=>screen_id ) if screen.nil?
	
    # Remove the mandetory options
    options.delete(:format)
    options.delete(:object)
    options.delete(:action)
    options.delete(:controller)
    options.delete(:screen_id)
    options.delete(:screen)
    options.delete(:row_id)
    options.delete(:action_type)
    options.delete(:error_msg)
	
    operation_result = object[:new_record_before_save] || false ? 'created' : 'updated'
    #    flash[:notice] = "#{screen} was successfully #{operation_result}."

    if screen.role_screens.is_a?(Array)
      #remove unused role_screens text 2009-10-09
      role_screens = screen.role_screens
      while !role_screens.empty? do
        role_screens.pop
      end
    end

    if screen.user_screens.is_a?(Array)
      #remove unused role_screens text 2009-10-09
      user_screens = screen.user_screens
      while !user_screens.empty? do
        user_screens.pop
      end
    end

    params = options.merge({:screen => screen.to_yaml, :row_id => row_id, :action_type => action_type, :action_source=>action_source, :pageno=>pageno, :error_msg => error_msg})
    format.html { redirect_to({:controller => 'front_desk', :action => 'welcome', :params=>params, :status => 302} ) }
    format.xml  { head :ok }
  end
  
  def back_to_operation_form(options={})
	  # Store the mandetory options 
	  format = options[:format]
	  controller = options[:controller]
	  action = options[:action]
	  object = options[:object]
	  # Remove the mandetory options
	  options.delete(:format)
	  options.delete(:controller)
	  options.delete(:action)
	  options.delete(:object)
	  
	  load_form_options
	  
	  format.html { render :controller => controller, :action => action, :params => options }
	  format.xml  { render :xml => object.errors, :status => :unprocessable_entity }
  end   
  
  def dump_fixture
	  model_class = self.class.name.to_s.gsub(/Controller/, '').singularize.constantize
	  Fixtures::dump(model_class)
  end

  def mem_stat
    if Rails.configuration.mem_state_interval > 0
      current_time = CustomFields::NumericField.floor_to(Time.now.strftime('%j%H%M').to_i, Rails.configuration.mem_state_interval).to_i

      @@mem_stat_check_point ||= nil

      if @@mem_stat_check_point != current_time
        @@mem_stat_check_point = current_time
        MemStat.new(request.port)
      end
    end
  end
  
  def client_env_load_files
    ClientEnv.load_files unless Rails.configuration.cache_classes
  end
end

class Document
  include Config
  
  def self.generate_report(xml_data, report_design, output_type, select_criteria)
    report_design << '.jasper' if !report_design.match(/\.jasper$/)
    interface_classpath = Dir.getwd + '/app/jasper/bin'
    case CONFIG['host']
    when /mswin32/
      mode = 'w+b' #windows requires binary mode
      Dir.foreach(Dir.getwd + '/app/jasper/lib') do |file|
        interface_classpath << ";#{Dir.getwd}/app/jasper/lib/" + file if (file != '.' and file != '..' and file.match(/.jar/))
      end
    else
      mode = 'w+'
      Dir.foreach(Dir.getwd + '/app/jasper/lib') do |file|
        interface_classpath << ":#{Dir.getwd}/app/jasper/lib/" + file if (file != '.' and file != '..' and file.match(/.jar/))
      end
    end
    result=nil
    
    cmd = <<CMD
java -Djava.awt.headless=true
  -cp "#{interface_classpath}" XmlJasperInterface
  -o#{output_type}
  -f#{Dir.getwd}/app/reports/#{report_design}
  -x#{select_criteria}
CMD
    IO.popen cmd, mode do |pipe|
      pipe.write xml_data
      pipe.close_write
      result = pipe.read
      pipe.close
    end
    return result
  end
end
