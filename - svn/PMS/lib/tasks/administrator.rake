namespace :admin do
  desc 'Get today\'s admin_sha'
  task :sha => :environment do
    puts ApplicationController.admin_sha
  end
  
  desc 'Initialize the adminitrator user'
  task :init => :environment do
    if ENV['PASSWORD'].to_s.empty?
          puts <<USAGE
Usage:
rake admin:init RAILS_ENV=environment PASSWORD=password
USAGE
    else
      User.create_tsestaff(ENV['PASSWORD'].to_s)
    end
  end
end
