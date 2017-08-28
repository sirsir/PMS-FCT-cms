class CreateMenuGroupScreens < ActiveRecord::Migration
  def self.up
    create_table :menu_group_screens do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :menu_group_screens
  end
end
