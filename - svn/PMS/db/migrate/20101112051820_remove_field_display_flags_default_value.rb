class RemoveFieldDisplayFlagsDefaultValue < ActiveRecord::Migration
  def self.up
    change_column :fields, :display_flags, :string
    change_column :custom_fields, :display_flags, :string
  end

  def self.down  
    #~ Do not restore
  end
end
