class AddFieldsDisplayFlags < ActiveRecord::Migration
  def self.up
      
    default_display_flags = {}
    labels = Label.find(:all, :conditions=>[" name IN (?)", ["G_List", "G_Search"]] ) 
    labels.each do |l|
        default_display_flags["#{l.id}"] = true
    end
    add_column :fields, :display_flags, :string, :default=>default_display_flags
    fields = Field.find(:all)
    fields.each do |f|
        f.display_flags = default_display_flags
        f.save
    end
    
  end
  
  def self.down
    remove_column :fields, :display_flags
  end
  
end
