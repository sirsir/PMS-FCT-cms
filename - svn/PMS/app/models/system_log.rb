# To change this template, choose Tools | Templates
# and open the template in the editor.

class SystemLog
  BYTES_PER_ROW = 0xFF
  ROWS_PER_LOG = RAILS_ENV =~ /development/ ? 0xFF : 0x10
  BYTES_PER_LOG = BYTES_PER_ROW * ROWS_PER_LOG

  class << self
    def logs(latest = 30)
      a_logs, file_size = tail(latest * BYTES_PER_LOG)

      while (a_logs.first =~ /^Processing /).nil?
        a_logs.delete_at(0)
      end

      logs = []

      skip = nil

      a_logs.each do |l|
        if l =~ /^Processing /
          skip = (l =~ /#{skipped_logs.join('|')}/)
          logs << { :key => l, :details => [l] } unless skip
        else
          logs.last[:details] << l unless skip || l.strip.empty?
        end
      end

      logs = logs.reverse.first(latest)

      logs.each{|l| l[:header] = parse(l) } 

      return logs, file_size
    end

    def tailed_log_file(size)
      a_logs, file_size = tail(size)

      log_file_name = Rails.configuration.log_path.gsub(File.join(RAILS_ROOT, 'log'), File.join(RAILS_ROOT, 'tmp', 'cache', 'mnt'))

      File.delete(log_file_name) if File.exist?(log_file_name)

      File.open(log_file_name, 'w') do |file|
        file.write(a_logs)
      end

      zip_file_name = log_file_name.gsub('.log', "_#{Time.now.strftime('%Y%m%d%H%M%S')}.zip")

      File.delete(zip_file_name) if File.exist?(zip_file_name)

      Zip::ZipFile.open(zip_file_name, Zip::ZipFile::CREATE) { |zipfile|
        store_file_name = File.basename(log_file_name)
        zipfile.add(store_file_name, log_file_name)
      }

      File.delete(log_file_name)
      
      zip_file_name
    end
    
    private
    
    def tail(size)
      file_size = nil
      a_logs = []

      File.open(Rails.configuration.log_path, 'r') do |file|
        file_size = File.size(file)
        seek_size = [size, file_size].min
        file.seek(-seek_size, IO::SEEK_END)
        a_logs = file.readlines
      end
      
      return a_logs, file_size
    end

    def skipped_logs
      %w(
      MaintenanceController#.*?_log
      MaintenanceController#search.*
      FrontDeskController#temp_form
      )
    end

    #   part(log) -> string
    # Parse the log to get each part
    #   log = <<LOG
    #     Processing FrontDeskController#login (for 192.168.1.20 at 2011-08-25 14:14:31) [POST]
    #      Session ID: 3f175a7324678a0cfe1288c26edc7436
    #      Parameters: {"user_login"=>"tsestaff", "action"=>"login", "authenticity_token"=>"a696cacd590fac2e04935b481df9c9eafa047f15", "controller"=>"front_desk", "user_password"=>"[FILTERED]", "login"=>"Login Â»"}
    #      ...
    #     Redirected to actionindex
    #     Completed in 78ms (DB: 0) | 302 Found [http://192.168.1.53/front_desk/login]
    #   LOG
    #
    #   {
    #     :date => 2011-08-25,
    #     :time => 14:14:31,
    #     :for  => '192.168.1.20',
    #     :controller => 'FrontDeskController',
    #     :action => 'login',
    #     :method => 'POST',
    #     :execution_time => '297ms',
    #     :result => '302 Found'
    #   }
    #
    #   log = <<LOG
    #     Processing MaintenanceController#system_log (for 127.0.0.1 at 2011-08-25 12:27:24) [GET]
    #       Session ID: 75f0196261ee6d5ab854664a21951ae2
    #      Parameters: {"action"=>"system_log", "id"=>"273", "controller"=>"maintenance"}
    #      ...
    #     NoMethodError (undefined method `keys' for #<Array:0x9369f08>):
    #         /app/models/system_log.rb:9:in #`logs'
    #         /app/models/system_log.rb:7:in `open#'
    #      ...
    #     Rendering E:/Projects/SUSBKK/STS/04_development/pms/vendor/rails/actionpack/lib/action_controller/templates/rescues/layout.erb (internal_server_error)
    #   LOG
    #
    #   {
    #     :date => 2011-08-25,
    #     :time => 12:27:24,
    #     :for  => '127.0.0.1',
    #     :controller => 'MaintenanceController',
    #     :action => 'system_log',
    #     :method => 'GET',
    #     :execution_time => '',
    #     :result => 'Error'
    #   }
    #
    #   log = <<LOG
    #     Processing RevisionRowsController#print (for 127.0.0.1 at 2011-08-25 15:40:38) [GET]
    #       Session ID: 18d44adbe056b73cd2e1505687acb28a
    #       Parameters: {"header_row_id"=>"252380", "print_id"=>"print", "rel"=>"external", "action"=>"print", "id"=>"252380", "controller"=>"revision_rows", "screen_id"=>"", "action_source"=>"index"}
    #     Filter chain halted as [:check_access_permission] rendered_or_redirected.
    #     Completed in 0ms (View: 0, DB: 32) | 200 OK [http://localhost/revision_rows/print/252380?action_source=index&header_row_id=252380&rel=external&screen_id=&print_id=print]
    #   LOG
    #
    #   {
    #     :date => 2011-08-25,
    #     :time => 15:40:38,
    #     :for  => '127.0.0.1',
    #     :controller => 'RevisionRowsController',
    #     :action => 'print',
    #     :method => 'GET',
    #     :execution_time => '0ms',
    #     :result => 'Denied'
    #   }
    #
    #   log = <<LOG
    #     Processing RevisionRowsController#relations (for 127.0.0.1 at 2011-08-25 15:28:04) [GET]
    #       Session ID: 18d44adbe056b73cd2e1505687acb28a
    #       Parameters: {"action"=>"relations", "id"=>"252379", "controller"=>"revision_rows", "screen_id"=>"181"}
    #       ...
    #     ActionController::UnknownAction (No action responded to relations. Actions: authorize, back_to_operation_form, check_access_permission, create, destroy, dump_fixture, edit, edit_header, edit_unsave_row, export, forward_to_front_desk, index, load_form_options, new, new_header, permission_map, permission_mapping, print, screen_from_action, set_cache_buster, set_charset, set_session_screen, and update):
    #         /vendor/rails/actionpack/lib/action_controller/filters.rb:617:in `call_filters'
    #         /vendor/rails/actionpack/lib/action_controller/filters.rb:610:in `perform_action_without_benchmark'
    #         ...
    #     Rendering E:/Projects/SUSBKK/STS/04_development/pms/vendor/rails/actionpack/lib/action_controller/templates/rescues/layout.erb (not_found)
    #   LOG
    #
    #   {
    #     :date => 2011-08-25,
    #     :time => 15:28:04,
    #     :for  => '127.0.0.1',
    #     :controller => 'RevisionRowsController',
    #     :action => 'relations',
    #     :method => 'GET',
    #     :execution_time => '',
    #     :result => 'Error'
    #   }
    def parse(log)
      request_log = log[:details].first.strip
      
      headers = request_log.split(/^Processing | \(for | at |\) \[|\]$/).last(4)

      last_detail = log[:details].last.strip
      if last_detail =~ /^Streaming file/
        last_detail = log[:details].last(2).first.strip
      end
      
      response_log = last_detail

      result = 'Error'
      http_status_code = 5
      
      # 1xx Informational
      # 2xx Success
      # 3xx Redirection
      # 4xx Client Error
      # 5xx Server Error
      http_status = {
        1 => 'Info',
        2 => 'OK',
        3 => 'Redirect',
        4 => 'Warning',
        5 => 'Error'
      }
      http_status.each do |c, m|
        if response_log =~ /(\| #{c}\d{2} |\(#{c}\d{2}.+?\))/
          http_status_code = c
          result = m
        end
      end

      if http_status_code == 2 && log[:details].reverse.any?{|l| l =~ /^Filter chain halted/}
        http_status_code = 3
        result = 'Denied'
      elsif http_status_code == 3 && response_log =~/^Completed in /
        http_status_code = 2
        result = http_status[http_status_code]
      end

        
      if http_status_code <= 3
        footers = response_log.split(/^Completed in |ms | \| | \[|\]$/).last(4)

        execution_time = footers[0]
      end

      header = {
        :controller => headers[0].split(/#/).first.gsub(/controller/i, ''),
        :action => headers[0].split(/#/).last,
        :for => headers[1],
        :date => headers[2].split(/ /).first,
        :time => headers[2].split(/ /).last,
        :method => headers[3],
        :execution_time => execution_time,
        :result => result,
        :http_status_code => http_status_code
      }

      header
    end

  end
end
