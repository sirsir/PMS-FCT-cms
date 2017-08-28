class AddColumnDeleteFlagInRow < ActiveRecord::Migration
  def self.up
    add_column :rows, :delete_flag, :boolean
  end

  def self.down
    remove_column :rows, :delete_flag
  end
end
