class CreateRows < ActiveRecord::Migration
  def self.up
    create_table :rows do |t|
      t.integer :screen_id

      t.timestamps
    end
  end

  def self.down
    drop_table :rows
  end
end
