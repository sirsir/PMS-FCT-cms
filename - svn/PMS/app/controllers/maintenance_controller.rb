require 'rake'
require 'rake/testtask'
require 'rdoc/task'

require 'tasks/rails'

class MaintenanceController < ApplicationController
  layout nil

  def permission_mapping
    super.merge(
      {
        'backup' => 'index',
        'restore' => 'edit',
        'restart' => 'index',
        'version' => 'index',
        'memory' => 'index',
        'memory_chart' => 'index',
        'firmware' => 'edit',
        'data_log' => 'index',
        'search_data_log' => 'index',
        'system_log' => 'index',
        'search_system_log' => 'index',
        'download_system_log' => 'index',
        'service' => 'index',
        'update_firmware' => 'edit',
        'clear_system_log' => 'edit',
        'reboot' => 'edit',
        'reboot_trigger' => 'edit'
      }
    )
  end

  def screen_from_action(params)
    Screen.find(params[:id])
  end
  
  def backup
    render :text => 'Coming Soon...' unless ApplicationController.admin_mode?
  end

  def restore
    render :text => 'Coming Soon...' unless ApplicationController.admin_mode?
  end

  def restart
  end

  def version
  end

  def firmware
  end

  def data_log
    render :text => 'Coming Soon...' unless ApplicationController.admin_mode?
  end

  def system_log
    @logs, @file_size = SystemLog.logs
  end

  def service
    render :text => 'Coming Soon...' unless ApplicationController.admin_mode?
  end

  def memory
    @mem_stat = MemStat.new(request.port)
  end

  def memory_chart
    image_path = MemStat.create_object_chart(request.port, params[:type], session.session_id)

    send_file image_path, :type => 'image/png', :disposition => 'inline'
  end

  def search
    screen_id = params[:id].to_i
    screen = Screen.find(screen_id)

    case screen.action
    when 'data_log', 'system_log'
      redirect_to :action => "search_#{screen.action}", :id => params[:id]
    else
      render :text => ''
    end
  end

  def search_data_log
  end

  def search_system_log
  end

  def reboot
    begin
      flash[:notice] = 'Please wait a while for the system to come back on-line...' unless flash[:error]
    rescue Exception => ex
      flash[:error] = 'Unable to urestarted the system.'
      log_error(ex)
    end

    ajax_url = url_for(:action => :restart, :id => params[:id])
    trigger_url = url_for(:action => :reboot_trigger, :id => params[:id])
    ui_feedback = <<JAVASCRIPT
fncHideDialog("pop_box");
fncAjaxUpdater('main','#{ajax_url}');
trigger_window = window.open("#{trigger_url}", "trigger_window", "location=0,status=0,scrollbars=0,toolbar=0,menubar=0,width=100,height=100");
trigger_window.document.write('<h1>Restarting Services...</h1>');
JAVASCRIPT

    update_ui_and_perform_next(ui_feedback)
  end

  def reboot_trigger
    render :text => `schtasks /Run /TN "Restart PMS"`
  end

  def update_firmware
    begin
      case params[:firmware_src]
      when 'file'
        case params[:file]
        when File, ActionController::UploadedStringIO, ActionController::UploadedTempfile
          filename = Upload.tmp_save(params[:file])
          filename = File.expand_path(filename, File.join(RAILS_ROOT, 'public'))

          Rake::Task['deploy:patch'].execute({:filename => filename})

          #~ Keep the uploaded file for reference
          #~ File.delete(File.join(RAILS_ROOT, 'public', filename) )
        else
          flash[:error] = 'Please specify the Patch File...'
        end
      when 'release_tag'
        if params[:release_tag].to_s =~ /^PMS(_[A-Z]+)?_RELEASE_\d{8}(_[0-9A-Z_]+)?$/
          raise 'Missing implementation'
          Rake::Task['deploy:patch'].execute({:release_tag => params[:release_tag]})
        else
          flash[:error] = 'Please specify a valid Release Tag...'
        end
      end

      Rake::Task['db:migrate'].execute unless flash[:error]
      Rake::Task['db:fixtures:setting:load'].execute unless flash[:error]

      flash[:notice] = 'Successfully updated firmware. Please restart the system...' unless flash[:error]
    rescue Exception => ex
      flash[:error] = 'Unable to update firmware.'
      log_error(ex)
    end
    
    render :status => 500 if flash[:error]
  end
  
  def clear_system_log
    begin
      Rake::Task['log:archive'].execute
      Rake::Task['log:clear'].execute

      flash[:notice] = 'Successfully cleared log...'
    rescue Exception => ex
      flash[:error] = 'Unable to cleared log.'
      log_error(ex)
    end

    ajax_url = url_for(:action => :system_log, :id => params[:id])
    ui_feedback = <<JAVASCRIPT
fncHideDialog("pop_box");
fncAjaxUpdater('main','#{ajax_url}');
JAVASCRIPT

    update_ui_and_perform_next(ui_feedback)
  end

  def clear_cache
    begin
      vm_group = params['clear'].to_s

      raise "Cache group not selected" if vm_group.empty?

      VirtualMemory.clear(vm_group)

      flash[:notice] = 'Successfully cleared cache...'
    rescue Exception => ex
      flash[:error] = 'Unable to cleared cache.'
      log_error(ex)
    end

    ajax_url = url_for(:action => :memory, :id => params[:id])
    ui_feedback = <<JAVASCRIPT
fncHideDialog("pop_box");
fncAjaxUpdater('main','#{ajax_url}');
JAVASCRIPT

    update_ui_and_perform_next(ui_feedback)
  end

  def download_system_log
     send_file SystemLog.tailed_log_file(params[:size].to_i), :type => 'application/zip'
  end
end
