class ModifiedColumnScreens < ActiveRecord::Migration
  def self.up
   add_column :screens,:action,:string
   add_column :screens,:controller,:string
  end

  def self.down
   remove_column :screens,:action
   remove_column :screens,:controller
  end
end
