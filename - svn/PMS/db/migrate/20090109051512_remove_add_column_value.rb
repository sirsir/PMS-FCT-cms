class RemoveAddColumnValue < ActiveRecord::Migration
  def self.up
	  remove_column :fields, :value
	  add_column :custom_fields, :value, :string
  end

  def self.down
	  add_column :fields, :value, :string
	  remove_column :custom_fields, :value
  end
end
