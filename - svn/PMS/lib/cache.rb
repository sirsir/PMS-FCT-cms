require 'fileutils'

module Cache

  # Remove the files in the cache_folder
  def Cache.purge_files
    Cache.each_file(Cache.files_to_remove) do |file_name|
      FileUtils.rm file_name, :force => true
    end
  end

  private

  # Populate the file names
  def Cache.each_file(files_or_folders)
    files_or_folders.each do |file_names|
      file_names = File.join(RAILS_ROOT, file_names)
      
      Dir.glob(file_names).each do |file_name|
        if File.ctime(file_name) < check_point
          yield file_name
        end
      end
    end
  end

  # List of files to remove
  def Cache.files_to_remove
    [
      Cache.cache_folder
    ].flatten
  end

  # List of files in the cache folders
  def Cache.cache_folder
    [
      Cache.fw_files,
      Cache.img_files,
      Cache.rpt_files,
      Cache.vm_files
    ].flatten.collect{|f| "tmp/cache/#{f}"}
  end

  # List of files from the FrameWork
  def Cache.fw_files
    %w(
      *.csv
      *.log
      *.zip
    ).collect{|f| "fw/#{f}"}
  end

  # List of temp image files
  def Cache.img_files
    %w(
      *.png
    ).collect{|f| "img/#{f}"}
  end

  # List of temp report files
  def Cache.rpt_files
    %w(
      *.pdf
    ).collect{|f| "rpt/#{f}"}
  end

  # List of temp VirtualMemory files
  def Cache.vm_files
    %w(
      screen_import/screen_import_*.*
      session/session_*.*
    ).collect{|f| "vm/#{f}"}
  end

  # Number of days to keep
  def Cache.purge_days
    30
  end

  # The number of seconds in a day
  def Cache.seconds_per_day
    60*60*24
  end

  # Time point to compare deletion
  def Cache.check_point
    @@check_point ||= Time.now - (purge_days * seconds_per_day)
  end
end

Cache.purge_files
VirtualMemory.clear(:view_cache)
VirtualMemory.clear(:field_cache)
