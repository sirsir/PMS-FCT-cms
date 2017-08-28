class Upload
  class << self
    def image_save(file, time)
      saved_file, saved_name = save(file, :attachments, time)

      saved_name
    end
  
    def file_save(file)
      now = Time.now.strftime('%Y%m%d%H%M%S')
      saved_file, saved_name = save(file, :uploadfiles, now)

      saved_name
    end

    def tmp_save(file)
      now = Time.now.strftime('%Y%m%d%H%M%S')
      saved_file, saved_name = save(file, '../tmp/cache/fw', now)

      saved_name
    end
  
    private
  
    def save(file, folder, timestamp)
      file_extname = File.extname(file.original_filename.downcase)
      file_name = File.basename(file.original_filename.downcase, file_extname).gsub(/[^0-9a-zA-Z]/,'_').gsub(/[_]+/,'_')
      saved_name = "#{folder.to_s}/#{file_name}_#{timestamp}#{file_extname}"
      path = "#{RAILS_ROOT}/public/#{saved_name}"
      saved_file = File.open(path, 'wb'){ |f| f.write(file.read) }
      return saved_file, saved_name
    end
  end
end