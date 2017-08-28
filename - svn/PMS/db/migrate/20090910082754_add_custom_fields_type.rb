class AddCustomFieldsType < ActiveRecord::Migration
  def self.up
    add_column :custom_fields, :type, :string, :null=>false, :default=>"CustomField"

    custom_fields = CustomField.find(:all)
    custom_fields.each {|cf|
      cf.type = "#{cf.field_type.name.gsub(/ /,"_").underscore.classify}CustomField"
      cf.save
    }
  end

  def self.down
    remove_column :custom_fields, :type
  end
end
