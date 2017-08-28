class CreateMaintenanceScreens < ActiveRecord::Migration
  def self.up
    permission_attributes = {
      :role_id => Role.find(:first, :conditions => { :roles => { :name => "Admin" } } ).id
    }

    maintenance_menu_group = nil
    languages = Language.find(:all)
    
    screens.each_with_index do |action, index|
      screen_name = sanitize_to_id(action).upcase

      puts "+ #{screen_name}"

      ActiveRecord::Base.transaction do
        label = Label.create(:name => "S_SCR_#{screen_name}")
        label.captions = languages.collect{|l| Caption.create(:name => screen_name.titleize, :language_id => l.id )}

        if action =~ /maintenance/
          screen = MenuGroupScreen.new(screen_attributes(screen_name, action, 7))

          screen.screen = Screen.find_by_name('root')
        else
          screen = Screen.new(screen_attributes(screen_name, action, index))

          screen.screen = maintenance_menu_group
        end
        
        screen.label = label

        screen.save

        maintenance_menu_group = screen if action =~ /maintenance/

        permission_attributes.update(
          :all => :true,
          :screen_id => screen.id
        )

        Permission.create_permissions(Permissions::RoleScreen, permission_attributes)
      end

    end
  end

  def self.down
    screens.reverse.each do |action|
      screen_name = sanitize_to_id(action).upcase

      puts "- #{screen_name}"

      ActiveRecord::Base.transaction do
        screen = Screen.find_by_name(screen_name)
        
        screen.label.destroy

        screen.destroy
      end
    end
  end

  private

  def self.screens
    %w(
      maintenance
      version
      service
      data_log
      system_log
      backup
      restore
      restart
      firmware
    )
  end
  
  def self.sanitize_to_id(name)
    name.to_s.gsub(/[^a-zA-Z0-9]/, "_").gsub(/[_]+/, "_")
  end


  def self.screen_attributes(screen_name, action, display_seq)
    {
      :name => screen_name,
      :display_seq => display_seq,
      :system => 1,
      :action => action,
      :controller => "maintenance"
    }
  end
end
