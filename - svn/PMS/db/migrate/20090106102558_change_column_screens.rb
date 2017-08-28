class ChangeColumnScreens < ActiveRecord::Migration
  def self.up
    remove_column :screens,:code
    add_column :screens,:system,:integer
  end

  def self.down
    add_column :screens,:code,:string
    remove_column :screens,:system
    end
end
