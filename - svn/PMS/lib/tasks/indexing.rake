namespace :db do
  namespace :screen do
    desc 'Rebuild all screen index files'
    task :rebuild_index => :environment do
      ApplicationController.enter_admin_mode(false)
      
      screens = Screen.find(:all).select{|s| !s.system? }
      screens.each do |s|
        next unless ENV['screen_id'].nil? || ENV['screen_id'].to_i == s.id

        puts "- #{s.name}"

        begin
          s.rebuild_index(nil, false, :report_progress => true)
        rescue Exception => ex
          puts ex.message
        end

        GC.start
      end
    end
  end

  namespace :custom_field do
    desc 'Rebuild all custom field index files'
    task :rebuild_index => :environment do
      ApplicationController.enter_admin_mode(false)

      custom_fields = CustomField.find(:all)
      custom_fields.each do |cf|
        next unless ENV['custom_field_id'].nil? || ENV['custom_field_id'].to_i == cf.id

        if cf.respond_to?(:rebuild_index)
          puts "- #{cf.name}"
          
          begin
            cf.rebuild_index(nil, false, :report_progress => true)
          rescue Exception => ex
            puts ex.message
          end  
        end
      end
    end
  end
end

# E:\Projects\TSE\_PMS\04_development\db>
# rake db:screen:rebuild_index RAILS_ENV=susbkk_development --trace

