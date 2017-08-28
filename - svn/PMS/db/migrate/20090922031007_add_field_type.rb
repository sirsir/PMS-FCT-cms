class AddFieldType < ActiveRecord::Migration
  def self.up
    add_column :fields, :type, :string, :null => false, :default=>"Fields::Data"
  end

  def self.down
    remove_column :fields, :type
  end
end
