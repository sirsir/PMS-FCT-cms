require 'win32/file'

ApplicationController.enter_admin_mode

def msg(text)
  puts "==== #{text} ===="
end

def err(text, file_name, line_no = nil)
  puts "ERROR! [#{File.basename(file_name, '.csv')} @ #{line_no}]\t#{text}"
end

def line_progress(counter, every = 1000)
  puts "#{'-' * 30} #{counter} records processed #{'-' * 30}" if counter % every == 0
end

def validate_unique(legacy_data_folders_or_files, unique_col_indexes)
  unique_col_indexes.sort!
  
  ht_values = {}
  ht = nil
  
  legacy_data(legacy_data_folders_or_files) do |values|
    unique_col_indexes.each do |i|
      ht = ht_values if i == unique_col_indexes.first
      
      if i != unique_col_indexes.last
        ht[values[i]] ||= {}
        ht = ht[values[i]]
      else
        ht[values[i]] ||= []
        ht[values[i]] << values
      end
    end
  end
  
  leafs(ht_values).sort
end

def leafs(ht_values)
  if ht_values.is_a?(Hash)
    result = []
    ht_values.values.each {|v| result += leafs(v)}
    result
  else
    ht_values.size == 1 ? [] : [ht_values.collect{|e| e.inspect}]
  end
end

def legacy_data(legacy_data_folders_or_files, archived_on_complete = false, has_header = true, lines = 0)
  lines ||= 0
  lines = lines + 1 if has_header && lines != 0

  legacy_data_file(legacy_data_folders_or_files, archived_on_complete) do |file_name, file|
    file.each_with_index do |line, i|
      next if has_header && i == 0
      break if lines != 0 && lines == i
      next if line =~ /^#/
      
      begin
        parsed = []
        CSV.parse_row(line.strip, 0, parsed)
        
        yield parsed.collect{|d| d.to_s.strip } + [file_name]
      rescue Exception => e
        err line.strip, file_name, i + 1
        raise e
      end
    end
  end
end

def legacy_data_file(legacy_data_folders_or_files, archived_on_complete = false)
  case legacy_data_folders_or_files
  when Array
    legacy_data_folders_or_files.each{|f| legacy_data_file(f, archived_on_complete) }
  else
    file_path = legacy_data_folders_or_files
    file_path = File.join(legacy_data_dir, file_path) unless file_path =~ /:/
    
    file_names = file_path
    if File.directory?(file_names.gsub('*.csv', ''))
      file_names.gsub!('*.csv', '')
      file_names = File.join(file_path,'**', '*.csv')
    end
    
    Dir.glob(file_names).each do |file_name|
      next unless File.archive?(file_name)

      File.open(file_name, 'r') do |f|
        begin
          file_basename = file_name.gsub(/(.*)\/([^\/]+\.csv)$/,'\2')

          yield file_basename, f

          `attrib -a "#{file_name.gsub('/','\\')}"` if archived_on_complete

        rescue Exception => e
          message = "#{e.class.name}: #{e.message}"
          err(message, file_name)
        end
      end
    end
  end
end

def legacy_data_dir
  unless @common_cache_fixtures_dir
    base_dir = File.join(Rails.root, default_legacy_data_path)

    raise  Exception.new("Missing fixture at '#{base_dir}'")  unless File.directory?(base_dir)

    @common_cache_fixtures_dir = base_dir
  end

  @common_cache_fixtures_dir
end

def default_legacy_data_path
  File.join(client_root.to_s, "db", "legacy_data")
end

def client_root
  path = File.join("client", Rails.configuration.client_code) unless RAILS_ENV =~ /^(development|test|production)$/
  path.to_s
end

def sanitize_to_id(name)
  name.to_s.gsub(/[^a-zA-Z0-9]/, "_").gsub(/[_]+/, "_")
end

def languages
  @common_cache_languages ||= Language.find(:all)
end

def screen_by_name(screen_name)
  screen_name = screen_name.to_s.strip

  @common_cache_screens ||= {}
  @common_cache_screens[screen_name] ||= Screen.find(:first,
    :conditions => {
      :screens => { :name => screen_name }
    }
  )
end

def field_by_name(screen_name, field_name)
  screen_name = screen_name.to_s.strip
  field_name = field_name.to_s.strip

  @common_cache_fields ||= {}
  @common_cache_fields[screen_name] ||= {}
  @common_cache_fields[screen_name][field_name] ||= screen_by_name(screen_name).fields.find(:first,
    :conditions => {
      :fields => { :name => field_name }
    }
  )
end

def custom_field_by_name(custom_field_name)
  custom_field_name = custom_field_name.to_s.strip

  @common_cache_custom_fields ||= {}
  @common_cache_custom_fields[custom_field_name] ||= CustomField.find(:first,
    :conditions => {
      :custom_fields => { :name => custom_field_name }
    }
  )
end

def reference_by_code(custom_field_name, code)
  code = code.to_s.strip

  @common_cache_reference_rows ||= {}
  @common_cache_reference_rows[custom_field_name] ||= {}

  if @common_cache_reference_rows[custom_field_name].empty?
    custom_field = custom_field_by_name(custom_field_name)
    custom_field.screen.rows.each do |r|
      row_code = r.description.split(/ /).first
      
      raise "Duplicate #{custom_field_name.titleize} '#{row_code}'" unless @common_cache_reference_rows[custom_field_name][row_code].nil?

      @common_cache_reference_rows[custom_field_name][row_code] = r
    end
  end

  @common_cache_reference_rows[custom_field_name][code]
end

def save(row, cell_attributes)
  cell_attributes.each do |cell_attr|
    row.cells << Cell.new(cell_attr)
  end

  ActiveRecord::Base.transaction do
    if row.save && row.cells.all?{|c| c.save }
      log_values = {}

      cell_attributes.each do |a|
        @custom_field_by_id ||= {}
        @custom_field_by_id[a[:field_id]] ||= CustomField.find(a[:field_id])

        log_values[a[:field_id]] = @custom_field_by_id[a[:field_id]].text(a[:value])
      end

      row.full_logs << FullLog.create(
        :action => "import",
        :user => @@tsestaff.login,
        :seq_no => 0,
        :value => log_values,
        :created_at => Time.now
      )
    else
      error_messages = [row.errors.full_messages.to_s]
      error_messages += row.cells.collect{|c| "#{c.field.name}: #{c.errors.full_messages.to_s}" }

      row.cells.clear

      raise error_messages.join("\n")
    end
  end
end

def reset_common_cache
  @common_cache_screens = nil
  @common_cache_fields = nil
  @common_cache_custom_fields = nil
  @common_cache_reference_rows = nil
  @custom_field_by_id = nil
end