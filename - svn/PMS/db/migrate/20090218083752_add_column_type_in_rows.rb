class AddColumnTypeInRows < ActiveRecord::Migration
  def self.up
    add_column :rows, :type, :string
  end

  def self.down
    remove_column :rows, :type
  end
end
