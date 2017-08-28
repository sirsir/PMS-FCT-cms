class GrantAllToAdmin < ActiveRecord::Migration
  def self.up
    admin_role = Role.find(:first, :conditions=>" name = 'Admin'")
    Screen.permissionable.each {|s|
      permission = Permissions::RoleScreen.new

      permission.role_id = admin_role.id
      permission.screen_id = s.id
      permission.actions = {:grant=>Permission.action_options[:screen]}

      permission.save
    }
    
  end

  def self.down
  end
end
