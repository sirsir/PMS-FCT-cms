module MaintenanceHelper
  def version_pms_data
    'pms'.titleize
  end

  def version_configuration_data
    conf = Rails.configuration
    %w(
    cache_classes
    dependency_loading
    whiny_nils
    root_path
    log_path
    log_level
    first_port
    listening_ports
    reserved_ports
    offline
    system_name
    system_descr
    client_code
    client_name
    null_date
    time_zone
    index_default_updated_at_filter
    ).each do |c|
      value = eval("conf.#{c}")
      case value
      when Hash, Array
        value = value.inspect
      end

      yield [:configuration, c], value
    end
  end

  def version_database_data
    conn = ActiveRecord::Base.connection
    conf = ActiveRecord::Base.configurations[RAILS_ENV]

    conf.delete('password')

    conf.each do |k,v|
      yield [:database, k], v
    end

    case conf['adapter']
    when 'mysql'  
      database_engine_version = conn.select_value('select VERSION() ')
    end 
    yield [:database, 'database_engine_version'], database_engine_version
  end

  def version_system_data
    %w(
SERVER_SOFTWARE
SERVER_PROTOCOL
SERVER_PORT
SERVER_NAME
REMOTE_USER
REMOTE_HOST
REMOTE_ADDR
HTTP_X_REQUESTED_WITH
HTTP_X_PROTOTYPE_VERSION
HTTP_USER_AGENT
HTTP_REFERER
HTTP_KEEP_ALIVE
HTTP_HOST
HTTP_COOKIE
HTTP_CONNECTION
HTTP_ACCEPT_LANGUAGE
HTTP_ACCEPT_ENCODING
HTTP_ACCEPT_CHARSET
HTTP_ACCEPT
GATEWAY_INTERFACE
    ).each do |e|
      yield [:system, e], request.env[e]
    end
  end

  def version_os_data
    'os'.titleize
  end
end
