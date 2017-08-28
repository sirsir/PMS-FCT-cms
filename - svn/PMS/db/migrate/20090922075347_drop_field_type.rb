class DropFieldType < ActiveRecord::Migration
  def self.up
    remove_column :custom_fields, :field_type_id
    drop_table :field_types
  end

  def self.down
    create_table :field_types do |t|
      t.string :name
      t.string :descr

      t.timestamps
    end
    field_types = {}
    CustomField.types.each {|t|
      field_type_name = t.class.name.gsub("CustomFields::", "").titleize
      field_types[field_type_name] =
        FieldType.new(:name=>field_type_name, :descr=>t.description)
      field_types[field_type_name].save
    }
    
    add_column :custom_fields, :field_type_id, :integer, :null=>false, :default=>0
    CustomField.find(:all).each {|cf|
      field_type_name = cf.class.name.gsub("CustomFields::", "").titleize
      cf[:field_type_id] = field_types[field_type_name].id
      cf.save
    }
  end
end
