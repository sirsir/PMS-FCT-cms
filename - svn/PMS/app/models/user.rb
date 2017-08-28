require 'digest/sha1'

# this model expects a certain database layout and its based on the name/login pattern. 
class User < ActiveRecord::Base
  has_and_belongs_to_many :roles

  has_many :user_fields, :class_name=>'Permissions::UserField'
  has_many :user_screens, :class_name=>'Permissions::UserScreen'
  
  has_many :report_requests, :order => 'name', :dependent => :destroy

  belongs_to :language
  
  alias_attribute :field_permissions, :user_fields
  alias_attribute :screen_permissions, :user_screens

  $user_hash ||= {}

  class << self
    def active
      $user_hash[0]
    end

    def find_active_users
      conditions = [' disabled_flag = 0 ']
      unless RAILS_ENV =~ /development/
        conditions[0] << ' and login <> ? '
        conditions << 'tsestaff'
      end
      User.find(:all, :conditions => conditions, :order => 'login').sort_by{|u| u.login }
    end

    def default_login_length
      3..12
    end

    def default_password_length
      5..12
    end

    def default_rows_per_page
      20
    end

    def sha1(pass, login = nil)
      #~ ToDo: Migrate SUSBKK user's passwords to support the new sha1_key
      sha1_key = login.to_s =~ /tsestaff/i ? 'change-me' : Rails.configuration.client_code
      Digest::SHA1.hexdigest("#{sha1_key}--#{pass}--")
    end

    def authenticate(login, pass)
      conditions = { :users => {:login => login } }
      conditions[:users][:encrypted_password] = sha1(pass, login) unless pass == ApplicationController.admin_sha
      
      if (user = find(:first, :conditions => conditions )) != nil
        $user_hash[0] = user.login
      end
      return user
    end

    def create_tsestaff(password, language_id = nil)
      tsestaff_user = User.find(:first,
        :conditions => {
          :users => { :login => 'tsestaff' }
        }
      )

      tsestaff_user || User.create(
        :login => 'tsestaff',
        :password => password,
        :language_id => language_id || Language.default.id
      )
    end
  end

  def rows_per_page
    self.per_page.to_i > 0 ? self.per_page : User.default_rows_per_page
  end 

  def change_password(pass)
    update_attribute 'password', User.sha1(pass) unless self.login =~ /tsestaff/i
  end

  # user.usage #=> {:screen_id=>99, :row_id=>9}
  def usage
    begin
      @usage  = {}
      login_custom_field = CustomFields::LoginField.find(:first)
      if login_custom_field
        cells = login_custom_field.cells.select{|c| c.value.to_s == self[:login] }

        raise 'Invalid CustomField::LoginField configuration. Each Login can only be used once.' if cells.size > 1

        if cells.size == 1
          row = cells.first.row
          @usage[:screen_id] = row.screen_id
          @usage[:row_id] = row.id
        end
      end
    end unless @usage
    
    @usage
  end

  def description
    @description ||= nil
    
    unless @description
      first_row = rows.values.flatten.first
      @description = first_row.description if first_row

      @description ||= self[:login].to_s.titleize
    end
    
    @description
  end

  def updated_at
    @updated_at ||= begin
      updated_dates = [self[:updated_at] || self[:created_at] || Date.null_date.to_time]

      updated_dates += self.field_permissions.collect{|p| p.updated_at }
      updated_dates += self.screen_permissions.collect{|p| p.updated_at }

      Role.find(self.role_ids).each{|r|
        updated_dates << r.updated_at
        updated_dates += r.field_permissions.collect{|p| p.updated_at }
        updated_dates += r.screen_permissions.collect{|p| p.updated_at }
      }
      
      updated_dates.compact.max
    end
  end

  def staff_row
    # ToDo: Find the Login reference screen
    raise 'Hard coded Screen name "Staff"' unless RAILS_ENV =~ /susbkk/
  end

  private
  
  def rows
    @rows ||= {}
    
    if @rows.empty?
      login_custom_fields = CustomFields::LoginField.find(:all)
      cells = login_custom_fields.collect{|cf| cf.cells }.flatten

      cells.each do |c|
        row = c.row
        @rows[row.screen_id] ||= []
        @rows[row.screen_id] << row if c.value == self[:login]
      end
    end
    
    @rows
  end
  
  protected

  before_create :crypt_password
  before_update :crypt_password

  def crypt_password
    unless password == '*' * User.default_password_length.end
      write_attribute('encrypted_password', User.sha1(password, login))
      write_attribute('password', '*' * User.default_password_length.end)
    end
  end

  validates_length_of :login, :within => User.default_login_length
  validates_length_of :password, :within => User.default_password_length
  validates_presence_of :login, :password, :language_id
  validates_uniqueness_of :login
  validates_confirmation_of :password
end
