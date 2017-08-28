class CreateAutoNumberRunnings < ActiveRecord::Migration
  def self.up
    create_table :auto_number_runnings do |t|
      t.integer :custom_field_id
      t.integer :key_hash
      t.integer :current

      t.timestamps
    end

    add_index :auto_number_runnings, [:custom_field_id], :name => "IX_auto_number_runnings_custom_field_id"
    add_index :auto_number_runnings, [:custom_field_id, :key_hash], :name => "IX_auto_number_runnings_custom_field_id_key_hash"
  end

  def self.down
    drop_table :auto_number_runnings
  end
end
