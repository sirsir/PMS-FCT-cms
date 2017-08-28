class AddColumnValueInFields < ActiveRecord::Migration
  def self.up
	  add_column :fields, :value, :string
  end

  def self.down
	  remove_column :fields, :value
  end
end
