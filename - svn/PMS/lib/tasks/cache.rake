namespace :cache do

  desc 'Clear all stored caches'
  task :clear => :environment do
    Rake::Task['cache:field:clear'].execute
    Rake::Task['cache:row:clear'].execute
    Rake::Task['cache:view:clear'].execute
  end

  desc 'Clear, and then call cache:view to recreate'
  task :reset => :environment do
    Rake::Task['cache:clear'].execute
    Rake::Task['cache:view:row'].execute
  end

  namespace :field do

    desc 'Clear all stored cached field values'
    task :clear => :environment do
      VirtualMemory.clear(:field_cache)
    end
  end

  namespace :row do

    desc 'Clear all stored cached row values'
    task :clear => :environment do
      VirtualMemory.clear(:row_cache)
    end
  end

  namespace :view do

    desc 'Clear all stored cached views'
    task :clear => :environment do
      VirtualMemory.clear(:view_cache)
    end

    desc 'Store all row results'
    task :row => :environment do
      ENV['port'] = Rails.configuration.first_port.to_s if ENV['port'].to_s.empty?
      
      uri_query = [
        "authentication_token=#{ApplicationController.admin_sha}"
      ].join('&')
      
      block_size = 100
      thread_count = Rails.configuration.listening_ports
      ports = (ENV['port'].to_i...ENV['port'].to_i+thread_count).to_a

      mutex = Mutex.new
      
      seconds = Benchmark.realtime do
        create_session do |http|
          screens = Screen.find(:all).select{|s| !s.system? && !s.is_a?(MenuGroupScreen) }.sort_by{|s| s.row_ids.size }

          (0...screens.size).step(thread_count) do |idx|
            threads = []
            (0...thread_count).each do |t|
              threads << Thread.new do
                s = screens[idx+t]
                print "- #{s.title}\n"

                record_count = s.rows.size
                s.row_ids.each_with_index do |r_id, i|
                  print "- #{s.title} > #{(100.0*(i + 1).to_f/record_count).to_s[0..4]}%\n" if (i+1) % block_size == 0

                  uri = URI("http://#{http.address}:#{ports[(idx+t)%thread_count]}/rows/fetch_row/#{r_id}")

                  uri.query = uri_query

                  request = Net::HTTP::Get.new uri.request_uri

                  begin
                    response = nil
                
                    mutex.synchronize { |e| response = http.request request }

                    if response.code.to_i >= 400
                      dump_error(error_filename, response.body)

                      raise "- #{s.title} # Access Denied\nSee '#{error_filename}' for details"
                    end
                  rescue Exception => ex
                    if ex.to_s !~ / # Access Denied/
                      dump_error(error_filename, ex.to_s)

                      raise "- #{s.title} # Error\nSee '#{error_filename}' for details"
                    end
                  end
                end
                print "- #{s.title} > 100.0%\n" if record_count > block_size && record_count % block_size != 0
              end
            end
          
            threads.each{|t| t.join }
          end
        end
      end

      puts "Completed (#{'%.1f' % (seconds * 1000)}ms)"
    end
  end
  
  private
  
  def dump_error(error_filename, response_body)
    File.open(error_filename, 'w') { |f| f.puts response_body }
  end

  def error_filename
    @error_filename = File.join(RAILS_ROOT, 'log', File.basename(__FILE__).gsub(/.\w+$/, '_error.html'))
  end

  def create_session
    Net::HTTPSession.start('localhost', ENV['port']) do |http|
      uri = URI("http://#{http.address}:#{http.port}/front_desk/login/0")
      uri.query = [
        "authentication_token=#{ApplicationController.admin_sha}"
      ].join('&')

      request = Net::HTTP::Get.new uri.request_uri
      
      response = http.request request

      if response.body !~ /login successful/i
        dump_error(error_filename, response.body)

        raise "Unable to login\nSee '#{error_filename}' for details"
      end
      
      yield http
    end
  end
end
