require 'active_record/fixtures'
#~ require 'win32/file'

class Fixtures < (RUBY_VERSION < '1.9' ? YAML::Omap : Hash)
  def self.create_fixtures(fixtures_directory, table_names, class_names = {})
    table_names = [table_names].flatten.map { |n| n.to_s }
    connection  = block_given? ? yield : ActiveRecord::Base.connection

    table_names_to_fetch = table_names.reject { |table_name| fixture_is_cached?(connection, table_name) }

    unless table_names_to_fetch.empty?
      ActiveRecord::Base.silence do
        connection.disable_referential_integrity do
          fixtures_map = {}

          fixtures = table_names_to_fetch.map do |fixture_name|
            table_name = fixture_name.gsub(/(_\d+){2}/, '')
            fixtures_map[table_name] = Fixtures.new(connection, File.split(table_name.to_s).last, class_names[table_name.to_sym], File.join(fixtures_directory, fixture_name.to_s))
          end

          all_loaded_fixtures.update(fixtures_map)

          connection.transaction(:requires_new => true) do
            fixtures.reverse.each { |fixture| fixture.delete_existing_fixtures } unless ENV['APPEND'].to_s.upcase == 'TRUE'
            fixtures.each { |fixture| fixture.insert_fixtures }

            # Cap primary key sequences to max(pk).
            if connection.respond_to?(:reset_pk_sequence!)
              table_names.each do |table_name|
                connection.reset_pk_sequence!(table_name)
              end
            end
          end

          cache_fixtures(connection, fixtures_map)
        end
      end
    end
    cached_fixtures(connection, table_names)
  end
  
  def self.load(model_class, options = {})
    defaults = {
      :check_archive_flag => false
    }
    options = defaults.merge(options)
    
    ActiveRecord::Base.establish_connection(Rails.env)
    table_name = model_class.to_s.tableize
    
    env_append = ENV['APPEND']

    (ENV['FIXTURES'] ? ENV['FIXTURES'].split(/,/).map {|f| File.join(fixtures_dir, f) } : Dir.glob(File.join(fixtures_dir, "#{table_name}*.{yml,csv}"))).each do |fixture_file|
      archive_flag = `attrib "#{File.dirname(fixture_file)}/*.*" | findstr \\#{File.basename(fixture_file, '.*')}`.first
      
      if fixture_file =~ /_0*1_\d+\./ || fixture_file !~ /_\d+_\d+\./
        puts "#{archive_flag != 'A' ? 'Skipping' : 'Loading to'} : #{table_name}"
      else
        ENV['APPEND'] = 'TRUE'
      end
      
      action_mark = case 
      when archive_flag != 'A' then
        '*'
      when ENV['APPEND'].to_s.upcase == 'TRUE' then
        '>'
      else
        ' '
      end
      puts " >#{action_mark} #{fixture_file.gsub(/.*_(\d+)_(\d+).*/, '\1 of \2')}" unless fixture_file !~ /_\d+_\d+\./

      if !options[:check_archive_flag] || archive_flag == 'A'
        Fixtures.create_fixtures(File.dirname(fixture_file), File.basename(fixture_file, '.*'))

        `attrib -a "#{fixture_file.gsub('/','\\')}"` if options[:check_archive_flag]
      end
    end

    ENV['APPEND'] = env_append
  end

  def self.dump(model_class)
    model_class = model_class.is_a?(Class) ? model_class : model_class.constantize rescue nil
    model_classes = []
    tb_row = model_class.find(:first)
    unless tb_row.nil? || tb_row[:type].nil?
      tb_rows = model_class.find(:all, :select => [:type], :group => [:type])
      model_classes += tb_rows.collect{|tr| tr.class.to_s.strip}
    end
    model_classes << model_class.to_s.strip
    patterns = model_classes.collect{|m| "object:#{m}.*\n"}

    regexp = Regexp.new(patterns.join('|') , Regexp::EXTENDED)

    output_path = "#{fixtures_dir}/#{model_class.to_s.tableize}.yml"

    dir = File.dirname(output_path)
    FileUtils.mkdir_p dir unless File.exist?(dir)
    
    puts "Writting to: #{output_path.gsub(RAILS_ROOT, '{RAILS_ROOT}')}"
    
    block_size = 10000
    record_count = model_class.count
    i = 0

    partitions = (record_count.to_f / block_size).ceil
    padding = partitions.to_s.length

    while true
      partition = ((i + 1).to_f / block_size).ceil
      
      records = model_class.find(:all, :limit => block_size, :offset => i)

      break if records.size == 0

      output_file = output_path.dup

      if partitions > 1
        output_file.gsub!('.yml', "_#{partition.to_s.rjust(padding, '0')}_#{partitions.to_s.rjust(padding, '0')}.yml")
      end

      File.open(output_file, 'w') do |f|
        f.puts records.collect{|r| r.to_fixture.gsub('--- !ruby/', '').gsub(regexp,'') }
      end

      puts " > #{i + records.size} records [#{(100.0*(i + records.size).to_f/record_count).to_s[0..4]}%]" if partitions > 1
      
      i += block_size  
    end
  end
  
  private
  
  def self.fixtures_dir
    unless @fixtures_dir
      base_dir = File.join(Rails.root, ENV['FIXTURES_PATH'] || default_fixtures_path)
      fd = ENV['FIXTURES_DIR'] ? File.join(base_dir, ENV['FIXTURES_DIR']) : base_dir

      raise  Exception.new("Missing fixture at '#{fd}'")  unless File.directory?(fd)

      @fixtures_dir = fd
    end
    
    @fixtures_dir
  end

  def self.default_fixtures_path
    client_root = File.join('client', Rails.configuration.client_code) unless RAILS_ENV =~ /^(development|test|production)$/
    File.join(client_root.to_s, 'db', 'fixtures')
  end
end

class ActiveRecord::Base
	
	def to_fixture_style;end 
	
	def to_fixture( opts = {} ) 
		YAML::quick_emit( self, opts ) do |out|
			out.map( taguri, to_fixture_style ) do |map| 
				map.add( "#{self.class.to_s.underscore.gsub(']','').gsub('/','_').gsub(/[^-a-zA-Z0-9:.]/, '_')}_#{self[:id]}", attributes )
			end
		end 
	end 
end 