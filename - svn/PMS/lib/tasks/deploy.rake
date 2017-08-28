require 'zip/zip'
require 'fileutils'

namespace :deploy do
  desc 'Export the latest version to the destination'
  task :export => :environment do
    host = ENV['HOST'].to_s
    user = ENV['USER'] || 'tsestaff'
    password = ENV['PASSWORD'] || 'tsetse'
    dest = ENV['DEST'] || '.'
    
    ENV['LC_MESSAGES'] = 'en_US'

    rev = ENV['REV'].to_s.strip
    ENV['ONLY'] = svn_mods(rev) unless rev.empty?
 
    only_folders = ENV['ONLY'].to_s.split(",").collect{|f| f.to_sym }
    exclude_folders = ENV['EXCLUDE'].to_s.split(",").collect{|f| f.to_sym }

    if !(RAILS_ENV =~ /production|test/) || !(rev.empty? || rev =~ /^\d+(-\d+)?$/)
      puts <<USAGE
Usage:
rake deploy:export RAILS_ENV=production (REV=rev_from-rev_to|ONLY=folder[,folder] EXCLUDE=folder[,folder]) ({DEST=folder}|{HOST=host USER=username PASSWORD=password})

Note:
 - Only the production/test type environments can be deployed (aaa_production, bbb_production, ...)
USAGE
    else
      if only_folders.empty?
        only_folders = rails_folders
        puts "Folders: All"
      else
        puts "Folders: #{only_folders.join(', ')}"
      end

      only_folders -= exclude_folders

      puts "Excluding: #{exclude_folders.join(', ')}"

      map_drive = "p" unless host.empty?

      if map_drive
        puts_line
        puts "Connecting to host's folder..."
        system "NET USE #{map_drive}: \\\\#{host}\\pms /USER:#{user} #{password}"

        path = "#{map_drive}:"
      else
        path = File.join(tmp_deploy_path,  "pms_#{Rails.configuration.client_code}")
        
        FileUtils.rm_rf(path) if File.exists?(path)
      end

      client_code = nil

      revisions = svn_export do |c, p, md5, o|
        case c
        when :tse
          p << path
          md5 << Rails.configuration.default_svn_client_mod5_code
          only_folders.each{|f| o << f }
        else
          client_code = c
          p << "#{path}/client/#{c}"
          md5 << Rails.configuration.svn_client_mod5_code
          # ToDo: Add argument to set which folders to deploy for client
          [:app, :config, :db, :public, :test].each{|f| o << f }
        end
      end

      if map_drive
        puts_line
        puts "Disconnecting from host's folder..."
        system "NET USE #{map_drive}: /DELETE"
      else
        client_revision = revisions.last if client_code && revisions.size > 1
        zip_output dest, path, revisions.first, client_code, client_revision
      end
    end
  end
  
  desc 'Patch and exported compress file to the RAILS_ROOT'
  task :patch, [:filename] => :environment do |t, args|
    file_name = args[:filename].to_s
    
    if file_name.empty?
      puts <<USAGE
Usage:
rake deploy:patch[filename]
USAGE
    else
      tmp = RAILS_ENV =~ /production/ ? '.' : 'tmp/pms'

      puts "WARNING!!! Result will be extracted to 'RAILS_ROOT/#{tmp}' of non production environments" unless RAILS_ENV =~ /production/
      
      Zip::ZipFile.open(file_name) { |zipfile|
        raise "Invalid File" unless zipfile.find_entry("pms_#{Rails.configuration.client_code}/public/version.txt")
        
        zipfile.each do |entry|
          path = File.expand_path(File.join(RAILS_ROOT, tmp, entry.name.gsub(/^pms_#{Rails.configuration.client_code}\//, '')))

          dir = entry.directory? ? path : File.dirname(path)
          FileUtils.mkdir_p dir unless File.exist?(dir)
          File.delete(path) if File.exist?(path) && File.file?(path)

          entry.extract(path){|e, destPath| true }
        end
      }
    end
  end

  private

  def svn_trunk(svn_client_mod5_code=nil)
    "https://subversion-server/svn/#{svn_client_mod5_code || Rails.configuration.default_svn_client_mod5_code}/pms/trunk"
  end

  def svn_export
    revisions = []

    [:tse, Rails.configuration.client_code].each do |client_code|
      path = ''
      svn_client_mod5_code = ''
      only_folders = []

      yield client_code, path, svn_client_mod5_code, only_folders
      
      # Export by folders
      only_folders.each do |f|
        puts_line f
        system "svn export --force #{svn_trunk(svn_client_mod5_code)}/#{f} #{path}/#{f}"
      end
      
      # Delete system files
      #    pms_system_folders.each do |f|
      #      File.delete( "#{path}app\\views\\#{f.to_s.pluralize}")
      #    end
      
      delete_files(path).each do |file_name|
        File.delete(file_name) if File.exists?(file_name)
      end
      
      Dir.mkdir("#{path}/public", 0x777) unless File.exist?("#{path}/public")
      
      svn_info = `svn info #{svn_trunk(svn_client_mod5_code)}`
      File.open("#{path}/public/version.txt", "w") do |f|
        svn_info.split(/\n/).each do |s|
          f.puts s.gsub(/Last Changed/, "").strip if s =~ /Last Changed/
          revisions << s.strip.split(/ /).last if s =~ /Last Changed Rev:/
        end
      end
    end

    revisions
  end

  def svn_mods(rev)
    if rev == '0'
      '.'
    elsif rev =~ /^\d+(-\d+)?$/
      revs = rev.split(/-/)

      rev = ([revs.first.to_i - 1, 0].max).to_s
      rev << ":#{revs.last}" unless revs.first == revs.last

      svn_diff = `svn diff -r #{rev} #{svn_trunk}`
      modified_paths = svn_diff.split(/\n/).collect do |s|
        s.gsub(/^Index: |\/[^\/]+$/, "").strip if s =~ /^Index: /
      end.compact.uniq.sort

      modified_paths.delete_if{|a| modified_paths.any?{|b| a =~ /^#{b}\// } }

      modified_paths.join(',')
    end
  end
  
  def puts_line(msg = "")
    puts "#{'=' * 40}#{msg}#{'=' * 40}"
  end

  def rails_folders
    [
      :app,
      :bin,
      :config,
      :db,
      :doc,
      :lib,
      :public,
      :script,
      :test,
      :tmp,
      :vendor,
      :Rakefile
    ]
  end

  def pms_system_folders
    [
      :caption,
      :custom_field,
      :label,
      :language,
      :report,
      :screen
    ]
  end
  
  def delete_files(path)
    [] +
      Dir.glob("#{path}/config/environments/*.rb").select{|f| (f =~ Regexp.new("#{RAILS_ENV}")).nil? } #+
#      Dir.glob("#{path}/client/*.").select{|f| (f =~ Regexp.new("#{Rails.configuration.client_code}")).nil? }
  end

  def tmp_deploy_path
    @temp_deploy_path ||= File.expand_path(File.join(RAILS_ROOT, 'tmp', 'deploy'))
  end

  def zip_output(dest, path, revision, client_code, client_revision)
    major = Rails.configuration.version[:major]
    minor = Rails.configuration.version[:minor]
    version = [major, minor, revision, client_code, client_revision].compact.join('.')
    dest = "#{File.expand_path(File.join(RAILS_ROOT, dest))}/pms_release.#{version}.zip"
    
    File.delete(dest) if File.exist?(dest)

    Zip::ZipFile.open(dest, Zip::ZipFile::CREATE) { |zipfile|
      file_names = []
      
      ['*.*', '*'].each do |pattern|
        file_names += Dir["#{path}/**/#{pattern}"].collect
      end
      
      file_names.uniq.sort.each do |file_name|
        store_file_name = file_name.gsub("#{tmp_deploy_path}/", '')
        if File.file?(file_name)
          zipfile.add(store_file_name, "#{file_name}")
        else
          zipfile.mkdir(store_file_name)
        end
      end
    }
    
    FileUtils.rm_rf(path)
  end
  
  def rmdir(path)
    if File.exist?(path)
      file_names = []
      
      ['*.*', '*'].each do |pattern|
        file_names += Dir["#{path}/**/#{pattern}"].select{|file_name|
          File.file?(file_name)
        }
      end
      
      file_names.uniq.sort \
        .each{|file_name|
          File.delete(file_name)
        }

      dir_names = []
      ['*', '*.*'].each do |pattern|
        dir_names += Dir["#{path}/**/#{pattern}"].collect
      end

      dir_names.uniq.sort{|a, b| b <=> a } \
          .each { |d|
            Dir.rmdir d
          }
      
      Dir.rmdir path if File.directory?(path)
    end
  end
end
