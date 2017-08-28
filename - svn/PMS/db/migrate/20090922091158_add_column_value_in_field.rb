class AddColumnValueInField < ActiveRecord::Migration
  def self.up
	add_column :fields,:value,:yaml
  end

  def self.down
	remove_column :fields,:value
  end
end
