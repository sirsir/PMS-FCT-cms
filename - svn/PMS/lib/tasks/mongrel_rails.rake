namespace :mongrel do
  desc 'Install mongrel_rails as a service'
  task :install => :environment do
    service_installation(:install)
  end

  desc 'Remove mongrel_rails from service'
  task :remove => :environment do
    service_installation(:remove)
  end

  desc 'Remove mongrel_rails from service'
  task :enable => :environment do
    service_installation(:enable)
  end

  desc 'Remove mongrel_rails from service'
  task :disable => :environment do
    service_installation(:disable)
  end

  desc 'Start the mongrel_rails services'
  task :start => :environment do
    service_running(:start)
  end

  desc 'Stop the mongrel_rails services'
  task :stop => :environment do
    service_running(:stop)
  end

  desc 'Restart all mongrel_rails services'
  task :restart => :environment do
    service_running(:restart)
  end

  private
  
  def service_installation(method)
    if method == :install
      descr = ENV['descr'] || Rails.configuration.system_descr
    end
    
    first_port = (ENV['first_port'] || Rails.configuration.first_port).to_i
    last_port = (ENV['last_port'] || first_port + Rails.configuration.listening_ports - 1).to_i
    
    name = ENV['name'] || Rails.configuration.system_name

    first_port.step(last_port, 1) do |p|
      intall_opt = <<OPT
-D "#{descr} (#{name}_#{p})" -e #{RAILS_ENV} -p #{p}
OPT
      cmd = <<CMD
call mongrel_rails service::#{method} -N #{name}_#{p} #{intall_opt if method == :install}
CMD

      system cmd if [:install, :remove].include?(method)
      system "sc config #{name}_#{p} start= #{method == :disable ? 'disabled' : 'auto'}" unless method == :remove
    end
  end

  def service_running(method)
    first_port = (ENV['first_port'] || Rails.configuration.first_port).to_i
    last_port = (ENV['last_port'] || first_port + Rails.configuration.listening_ports - 1).to_i

    name = ENV['name'] || Rails.configuration.system_name

    methods = [:stop, :start]
    
    case method
    when :start then methods.delete(:stop)
    when :stop then methods.delete(:start)
    end
    
    Rake::Task['log:archive'].invoke if methods.include?(:start)

    first_port.step(last_port, 1) do |p|
      methods.each do |m|
        if os_platform == :mswin32
          puts `call #{RAILS_ROOT}/bin/win32/startup_service.cmd #{m} #{name} #{p}`
        else
          puts `#{RAILS_ROOT}/bin/unix/startup_service.sh #{m} #{name} #{p}`
        end          
      end
    end
  end
  
  def os_platform
    RUBY_PLATFORM =~ /\w+\-(mswin32|mingw32)/ ? :mswin32 : :linux
  end
end
