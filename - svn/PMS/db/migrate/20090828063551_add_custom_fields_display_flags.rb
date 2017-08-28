class AddCustomFieldsDisplayFlags < ActiveRecord::Migration
  def self.up
    default_display_flags = {}
    
    labels = Label.find(:all, :conditions=>[" name IN (?)", ["G_List", "G_Search"]] ) 
    labels.each do |l|
      default_display_flags[l.id] = true
    end
    
    add_column :custom_fields, :display_flags, :string, :default=>default_display_flags
    
    custom_fields = CustomField.find(:all)
    
    custom_fields.each do |cf|
      cf.display_flags = default_display_flags
      cf.save
    end
    
  end

  def self.down
    remove_column :custom_fields, :display_flags
  end
end
