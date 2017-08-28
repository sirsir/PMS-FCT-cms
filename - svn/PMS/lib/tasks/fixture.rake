namespace :db do
  task :puts => :environment do
    puts RAILS_ENV
  end

  namespace :fixtures do
    namespace :setting do
      desc 'Export setting data from database to fixtures'
      task :dump => :environment do
        system_models.each do |m|
          Fixtures.dump(m)
        end
      end

      desc 'Import setting data from fixtures to database'
      task :load => :environment do
        system_models.each do |m|
          Fixtures.load(m)
        end
      end
    end

    namespace :data do
      desc 'Export data from database to fixtures'
      task :dump => :environment do
        data_models.each do |m|
          Fixtures.dump(m)
        end
      end

      desc 'Import data from fixtures to database'
      task :load => :environment do
        data_models.each do |m|
          Fixtures.load(m, :check_archive_flag => true)
        end
      end
    end
    
    namespace :user do
      desc 'create user "tsestaff" to users table'
      task :create => :environment do
        user = User.create(
          :login => 'tsestaff',
          :password => 'tsetse',
          :per_page => 20,
          :disabled_flag => false
        )
        raise user.errors.full_messages.inspect unless user.errors.full_messages.empty?
      end

      desc 'drop user "tsestaff" from users table'
      task :drop => :environment do
        user = User.find(:first, :conditions => ["login = 'tsestaff'"])    
        user.destroy
        
        raise user.errors.full_messages.inspect unless user.errors.full_messages.empty?
      end
    end
  end
end

def system_models
 [Caption,
  CustomField,
  Field,
  FieldsReport,
  FieldReportFilter,
  Label,
  Language,
  Report,
  ReportTemplate,
  Screen]
end

require 'active_record'
class RolesUser < ActiveRecord::Base
end

def data_models
  [
    AutoNumberRunning,
    Cells::CalendarValue,
    Cell,
    Cells::DateTimeRangeValue,
    FieldFilter,
    FullLog,
    Permission,
    ReportRequest,
    ReportRequestCell,
    ReportRequestCol,
    ReportRequestRow,
    Role,
    RolesUser,
    Row,
    Stock,
    StockDetail,
    StockItem,
    StockTransaction,
    User
  ]
end

# E:\Projects\TSE\_PMS\04_development\db>
# rake db:fixtures:dump APPEND=false FIXTURES_PATH=db/fixtures RAILS_ENV=susbkk_development --trace
# rake db:fixtures:load APPEND=false FIXTURES_PATH=db/fixtures RAILS_ENV=susbkk_production --trace

