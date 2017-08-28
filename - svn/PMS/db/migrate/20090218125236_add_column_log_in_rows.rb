class AddColumnLogInRows < ActiveRecord::Migration
  def self.up
    add_column :rows, :log, :yaml
  end

  def self.down
    remove_column :rows, :log
  end
end
