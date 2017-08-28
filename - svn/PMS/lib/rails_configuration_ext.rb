module Rails
  class Configuration
    unless method_defined?(:orig_initialize)
      alias_method :orig_initialize, :initialize
    end

    def client_folder
      'client'
    end
  
    def version
      unless @version
        defaults = {
          :major => 0,
          :minor => 3,
          :rev => 0,
          :author => '',
          :date => Date.null_date,
          :client_rev => 0,
          :client_author => '',
          :client_date => Date.null_date
        }

        @version = defaults

        [:tse, Rails.configuration.client_code].each do |c|
          path = (c == :tse) ? '.' : "#{client_folder}/#{c}"
          File.open(File.join(RAILS_ROOT, path, 'public/version.txt'), 'r') do |f|
            f.each do |l|
              k = "#{'client_' unless c == :tse}#{l.split(/: /).first.strip.downcase}".to_sym
              v = l.split(/: /).last.strip

              @version[k] = v
            end
          end
          
        end
      end

      @version
    end

    def env_client_code
      RAILS_ENV.gsub(/_(development|test|production)/, '')
    end
    
    # Loads and returns the contents of the #database_configuration_file. The
    # contents of the file are processed via ERB before being sent through
    # YAML::load.
    def database_configuration
      require 'erb'
      database_configurations = IO.read(database_configuration_file)

      client_config_path = "/#{client_folder}/#{env_client_code}\\1"
      client_database_configuration_file = database_configuration_file.gsub(/(\/config\/)/, client_config_path)
      database_configurations << IO.read(client_database_configuration_file) if File.exists?(client_database_configuration_file)
      
      YAML::load(ERB.new(database_configurations).result)
    end

    # Determine if the current  database is ready to be used
    def valid_database?
      @@valid_database ||= begin
        vm = VirtualMemory.load(:session, :database_setting, :YAML)

        @@valid_database = vm[:valid] || validate_database(vm)
      end
    end

    #   Rails.configuration.database_setting  -> String
    # Load the database settings from cache
    def database_setting
      VirtualMemory.load(:session, :database_setting, :YAML)[:html]
    end
    
    private
    
    # Determine if the current database is ready to be used
    def validate_database(vm)
      valid = true
      
      results = ""
      
      check_points.each do |cp, cmd|
        msg = ""
        
        if valid
          begin
            conn =  ActiveRecord::Base.connection
            value = conn.select_value(cmd, cp)
            valid = false unless value.to_i > 0
          rescue Exception => ex
            msg = ex.to_s
            valid = false
          end
        end
        
        results << <<HTML_TAGS
  <tr>
    <td>#{cp.to_s.titleize}</td>
    <td><img src='/images/permissions/#{valid ? 'grant' : 'revoke'}_all.gif' title='#{msg.gsub(",",'')}' />
  </tr>
HTML_TAGS
      end
      
      vm[:html] = <<HTML_TAGS
<table>
#{results}
</table>
HTML_TAGS
      
      vm[:valid] = valid

      VirtualMemory.store(:session, :database_setting, vm, :YAML)

      valid
    end

    def check_points
      [
        [:access_database,            " SELECT 1 "],
        [:session_table,              " SELECT count(*)+1 FROM sessions "],
        [:caption_table,              " SELECT count(*) FROM captions "],
        [:custom_field_table,         " SELECT count(*)+1 FROM custom_fields "],
        [:field_table,                " SELECT count(*)+1 FROM fields "],
        [:fields_report_table,        " SELECT count(*)+1 FROM fields_reports "],
        [:field_report_filter_table,  " SELECT count(*)+1 FROM field_report_filters "],
        [:label_table,                " SELECT count(*) FROM labels "],
        [:language_table,             " SELECT count(*) FROM languages "],
        [:report_table,               " SELECT count(*)+1 FROM reports "],
        [:screen_table,               " SELECT count(*) FROM screens "],
        [:adminitrator_user,          " SELECT count(*) FROM users WHERE login = 'tsestaff'"]
      ]
    end
  end
end

attributes = {
  :first_port => 3000,
  :listening_ports => 1,
  :reserved_ports => {
    :report_request => 0
  },
  :firewall => %w(),
  :offline => false,
  :null_date => '2000/01/01',
  :index_default_updated_at_filter => 1,
  :system_name => 'pms',
  :system_descr => 'Project Management System',
  :client_name => 'Thai Software Engineering Co.,Ltd.',
  :client_code => 'tse',
  :logo_file_name => 'logo.png',
  :svn_client_mod5_code => 'bd5a2cb40637623177295aed22db25f9',
  :support_email => 'pms_support@tse.in.th',
  :cache_expiration => 60 * 60,
  :mem_state_interval => 10
}

attr_accessors = []
init_attributes = []
def_defaults = []

attributes.each do |k, v|
  attr_accessors << <<ATTR_ACCESSOR
    attr_accessor :#{k}
ATTR_ACCESSOR

  init_attributes << <<INIT_ATTR
      self.#{k} = default_#{k}
INIT_ATTR

  def_defaults << <<DEF_DEFAULT
    def default_#{k}
      YAML.load("#{v.to_yaml.gsub(/\n/,'\\n')}")
    end
DEF_DEFAULT
end

eval <<RAILS_CONFIG
module Rails
  class Configuration

#{attr_accessors.join()}

    def initialize
      orig_initialize

#{init_attributes.join()}
    end

#{def_defaults.join()}
  end
end
RAILS_CONFIG

ENV['RAILS_PORT'] ||= begin
  net_stat =`netstat -aon`
  net_stat = net_stat.split("\n")
  net_stat.delete('')
  net_stat = net_stat[2...net_stat.size]
  net_stat = net_stat.collect{|s| s.split(/ +/) if s.split(/ +/).last == $$.to_s}.compact
  listener = net_stat.first[2]

  listener.split(/:/).last
rescue
  nil
end