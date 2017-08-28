class CreatePermissions < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      t.integer :role_id
      t.integer :user_id
      t.integer :screen_id
      t.integer :field_id
      t.yaml :actions
      t.string :type

      t.timestamps
    end
  end

  def self.down
    drop_table :permissions
  end
end
