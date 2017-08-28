namespace :db do
  task :puts => :environment do
    puts RAILS_ENV
  end

  namespace :create do
    desc 'Create all the local databases defined in config/database.yml (+SqlServer)'
    task :all => :environment do
      ActiveRecord::Base.configurations.each_value do |config|
        # Skip entries that don't have a database key, such as the first entry here:
        #
        #  defaults: &defaults
        #    adapter: mysql
        #    username: root
        #    password:
        #    host: localhost
        #
        #  development:
        #    database: blog_development
        #    <<: *defaults
        next unless config['database']
        # Only connect to local databases
        local_database?(config) { create_database_(config) }
      end
    end
	
    desc 'Create all the users defined in config/database.yml (+MySql)'
    task :user => :environment do
	  config = ActiveRecord::Base.configurations[RAILS_ENV || 'development']
      create_user(config)
    end
	
	def create_user(config)
	  puts "Creating #{config['username']} for #{config['database']}. Using #{ENV['root_pwd']}"
	  username = config['username']
	  password = config['password']
	  config['username'] = 'root'
	  config['password'] = ENV['root_pwd']
	  
	  ActiveRecord::Base.establish_connection(config)
	  
	  config['username'] = username
	  config['password'] = password
	  
	  # ActiveRecord::Base.connection.create_user(config)
	  ActiveRecord::Base.connection.execute "GRANT ALL ON #{config['database']}.* TO '#{config['username']}'@'localhost' IDENTIFIED BY '#{config['password']}';"
	end
  end

  desc 'Create the database defined in config/database.yml for the current RAILS_ENV (+SqlServer)'
  task :create => :environment do
    create_database_(ActiveRecord::Base.configurations[RAILS_ENV || 'development'])
  end

  def create_database_(config)
    begin
      if config['adapter'] =~ /sqlserver/
          begin
            # Create the SQLServer database
            ActiveRecord::Base.establish_connection(config)
            ActiveRecord::Base.connection.create_database(config['database'])
          rescue
            $stderr.puts $!, *($!.backtrace)
            $stderr.puts "Couldn't create database for #{config.inspect}"
          end
        return # Skip the else clause of begin/rescue
      else
	    config['username'] = 'root'
	    config['password'] = ENV['root_pwd']
	    puts "Creating #{config['username']} for #{config['database']}. Using #{config['password']}"
        create_database(config)
      end
    rescue
    else
      $stderr.puts "Unknown errr creating #{config['database']}"
    end
  end

  namespace :drop do
    desc 'Drops all the local databases defined in config/database.yml (+SqlServer)'
    task :all => :environment do
      ActiveRecord::Base.configurations.each_value do |config|
        # Skip entries that don't have a database key
        next unless config['database']
        # Only connect to local databases
        local_database?(config) { drop_database_(config) }
      end
    end
  end

  desc 'Drops the database for the current RAILS_ENV (+SqlServer)'
  task :drop => :environment do
    config = ActiveRecord::Base.configurations[RAILS_ENV || 'development']
    begin
      drop_database_(config)
    rescue Exception => e
      puts "Couldn't drop #{config['database']} : #{e.inspect}"
    end
  end
end

def drop_database_(config)
  case config['adapter']
  when 'sqlserver'
    ActiveRecord::Base.connection.drop_database config['database']
  else
    drop_database(config)
  end
end

