class AddUniqueFieldInFields < ActiveRecord::Migration
  def self.up
	  add_column :fields, :unique, :integer
  end

  def self.down
	  remove_column :fields, :unique
  end
end
