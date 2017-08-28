class AddColumnScreenIcon < ActiveRecord::Migration
  def self.up
    add_column :screens, :icon, :string
  end

  def self.down
    remove_column :screens, :icon
  end
end
