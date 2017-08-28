class User < ActiveRecord::Base
  validates_length_of :password, :within => 5..40
end

class MovePasswordsToEncryptedPassword < ActiveRecord::Migration
  def self.up
    add_column :users, :encrypted_password, :string
    
    users = User.find(:all, :include_disabled => true)
    users.each do |u|
      u.encrypted_password = u.password
      u.password = '*' * User.default_password_length.end

      u.save
    end
  end

  def self.down
    users = User.find(:all)
    users.each do |u|
      u.password = u.encrypted_password
      
      u.save
    end
    
    remove_column :users, :encrypted_password
  end
end
