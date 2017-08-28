class CreateFields < ActiveRecord::Migration
  def self.up
    create_table :fields do |t|
      t.integer :screen_id
      t.integer :custom_field_id
      t.integer :display_seq

      t.timestamps
    end
  end

  def self.down
    drop_table :fields
  end
end
