class AddColumnValueTableScreens < ActiveRecord::Migration
  def self.up
    add_column :screens, :value, :yaml
  end

  def self.down
    remove_column(:screens, :value )
  end
end
