class Language < ActiveRecord::Base
  has_many :captions, :dependent => :destroy
  has_many :users, :dependent => :nullify
  
  def Language.active
    if ApplicationController.current_user.language
      user_language_name = ApplicationController.current_user.language.name
      
      @@cached_languages ||= {}
      @@cached_languages[user_language_name] ||= Language.find(:first, :conditions=>['name = ?', user_language_name])
    else
      Language.default
    end
  end

  def Language.default
    user_language_name = 'EN'

    @@cached_languages ||= {}
    @@cached_languages[user_language_name] ||= Language.find(:first, :conditions=>['name = ?', user_language_name])
  end

  alias_attribute :description, :name
  
  validates_presence_of :name
  validates_uniqueness_of :name
end