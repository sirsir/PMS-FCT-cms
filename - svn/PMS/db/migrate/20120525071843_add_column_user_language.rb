class AddColumnUserLanguage < ActiveRecord::Migration
  def self.up
    add_column :users, :language_id, :integer

    language = Language.find(:first)

    users = User.find(:all)
    users.each do |u|
      u.language = language
      u.save
    end
  end

  def self.down
    remove_column :users, :language_id
  end
end
