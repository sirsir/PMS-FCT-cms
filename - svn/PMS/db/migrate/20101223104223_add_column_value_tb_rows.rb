class AddColumnValueTbRows < ActiveRecord::Migration
  def self.up
    add_column(:rows, :value, :yaml)
  end

  def self.down
    remove_column(:rows, :value)
  end
end
