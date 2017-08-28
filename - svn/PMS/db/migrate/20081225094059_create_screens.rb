class CreateScreens < ActiveRecord::Migration
  def self.up
    create_table :screens do |t|
      t.string :name
      t.integer :screen_id
      t.string :code
      t.integer :label_id

      t.timestamps
    end
  end

  def self.down
    drop_table :screens
  end
end
