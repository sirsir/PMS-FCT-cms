require 'fileutils'

module ClientEnv

  def ClientEnv.root
    @@client_env_root ||= begin
      path = File.join('client', Rails.configuration.client_code) unless RAILS_ENV =~ /^(development|test|production)$/
      path.to_s
    end
  end

  def ClientEnv.copy_files
    ClientEnv.each_file(ClientEnv.files_to_copy) do |file_name|
      FileUtils.cp file_name, file_name.gsub(ClientEnv.root, '.')
    end
  end

  def ClientEnv.load_files
    ClientEnv.each_file(ClientEnv.files_to_load) do |file_name|
      require_or_load file_name
    end
  end

  private
  
  def ClientEnv.each_file(files_or_folders)
    files_or_folders.each do |file_names|
      file_names = File.join(RAILS_ROOT, ClientEnv.root, file_names)
      
      Dir.glob(file_names).each do |file_name|
        yield file_name
      end
    end unless ClientEnv.root.empty?
  end

  def ClientEnv.files_to_copy
    [
      ClientEnv.config_folder,
      ClientEnv.public_folder
    ].flatten
  end

  def ClientEnv.files_to_load
    [
      ClientEnv.app_folder
    ].flatten
  end
  
  def ClientEnv.app_folder
    [
      ClientEnv.controller_files,
      ClientEnv.helper_files,
      ClientEnv.model_files,
      ClientEnv.report_files
    ].flatten.collect{|f| "app/#{f}"}
  end
  
  def ClientEnv.controller_files
    %w(
    *.rb
    ).flatten.collect{|f| "controllers/#{f}"}
  end
  
  def ClientEnv.helper_files
    %w(
    *.rb
    ).flatten.collect{|f| "helpers/#{f}"}
  end
  
  def ClientEnv.model_files
    %w(
    **/*.rb
    ).flatten.collect{|f| "models/#{f}"}
  end
  
  def ClientEnv.report_files
    %w(
    ).flatten.collect{|f| "reports/#{f}"}
  end

  def ClientEnv.config_folder
    [
    ].flatten.collect{|f| "config/#{f}"}
  end

  def ClientEnv.public_folder
    [
      ClientEnv.image_files,
      ClientEnv.javascript_files,
      ClientEnv.stylesheet_files
    ].flatten.collect{|f| "public/#{f}"}
  end

  def ClientEnv.image_files
    %w(
      logo_small.png
      logo_small_light.png
    ).collect{|f| "images/#{f}"}
  end

  def ClientEnv.javascript_files
    %w(
    ).collect{|f| "javascripts/#{f}"}
  end

  def ClientEnv.stylesheet_files
    %w(
    ).collect{|f| "stylesheets/#{f}"}
  end
end

ClientEnv.copy_files
ClientEnv.load_files
