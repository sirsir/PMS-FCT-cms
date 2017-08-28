require 'zip/zip'

namespace :db do
  namespace :schema do
    desc "Create a db/schema.rb file that can be portably used against any DB supported by AR"
    task :dump => :environment do
      require 'active_record/schema_dumper'
      File.open(ENV['SCHEMA'] || File.join(RAILS_ROOT, default_schema_path), "w") do |file|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
    end

    desc "Load a schema.rb file into the database"
    task :load => :environment do
      file = ENV['SCHEMA'] || File.join(RAILS_ROOT, default_schema_path)
      load(file)
    end
  end

  task :backup => :environment do
    config = ActiveRecord::Base.configurations[RAILS_ENV]

    interval = [ENV['INTERVAL'].to_i, 0].max
    copies = [ENV['COPY'].to_i, 0].max

    while true
      file_names = Dir.glob(File.join(RAILS_ROOT, 'db', 'backup', "*.zip")).to_a
      file_names[0..file_names.size-copies].each do |file_name|
        File.delete(file_name)
      end if copies > 0 && file_names.size >= copies

      timestamp = Time.now.strftime("%Y%m%d%H%M%S")
      file_name = File.join(RAILS_ROOT, 'db', 'backup', "#{config['database']}_#{timestamp}")

      puts "- #{File.basename(file_name)}"
      
      case config['adapter']
      when 'mysql'
        cmd = mysql_cmd(config, file_name)
        ext = mysql_ext
      end

      system cmd

      Zip::ZipFile.open("#{file_name}.zip", Zip::ZipFile::CREATE) { |zipfile|
        file_name = "#{file_name}.#{ext}"
        zipfile.add( File.basename(file_name), file_name)
      }
      File.delete(file_name)

      break if interval == 0
      
      sleep(interval * 60*60 )
    end
  end

  
  namespace :charset do
	  desc "Change the cells.value field char set to utf8"
	  task :cells => :environment do
      charset_utf8('cells', 'value')
	  end
	  
	  desc "Change the captions.name field char set to utf8"
	  task :captions => :environment do
      charset_utf8('captions', 'name')
	  end
  end
	  
  private
  
  def charset_utf8(table, field)
    config =  Rails.configuration.database_configuration[Rails.env]

    puts "config['database'] is #{config['database']}"
    conn = ActiveRecord::Base.connection
    conn.execute <<SQLCMD
ALTER TABLE `#{config['database']}`.`#{table}` MODIFY COLUMN `#{field}` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_general_ci;
SQLCMD
  end

  def mysql_cmd(config, file_name)
    <<CMD_LINE
"mysqldump" --host=#{config['host']} --user=#{config['username']} --password=#{config['password']} --result-file=#{file_name}.#{mysql_ext} #{config['database']}
CMD_LINE
  end
  
  def mysql_ext
    'sql'
  end
end

def default_schema_path
  client_root = File.join("client", Rails.configuration.client_code) unless RAILS_ENV =~ /^(development|test|production)$/
  File.join(client_root.to_s, "db", "schema.rb")
end