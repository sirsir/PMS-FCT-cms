class AddRelateScreenInScreen < ActiveRecord::Migration
  def self.up
    add_column :screens, :relate_screen, :integer
  end

  def self.down
    remove_column :screens, :relate_screen
  end
end
