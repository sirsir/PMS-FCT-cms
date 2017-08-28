require 'zip/zip'

namespace :log do
  desc "Compress all *.log files in log/ to zip file"
  task :archive do
    FileList["log/*.log"].each do |log_file|
      timestamp = Time.now.strftime("%Y%m%d%H%M%S")
      dest = log_file.gsub(/\.log/, "_#{timestamp}.zip")

      File.delete(dest) if File.exist?(dest)
      
      Zip::ZipFile.open(dest, Zip::ZipFile::CREATE) { |zipfile|
        store_file_name = File.basename(log_file)
        zipfile.add(store_file_name, "#{log_file}")
      } if File.size(log_file) > 0
    end
    
    Rake::Task['log:clear'].execute
  end
end