class AddColumnAliasScreenInScreen < ActiveRecord::Migration
  def self.up
    add_column :screens, :alias_screen, :integer
  end

  def self.down
    remove_column :screens, :alias_screen
  end
end
