class CreateCustomFields < ActiveRecord::Migration
  def self.up
    create_table :custom_fields do |t|
      t.string :name
      t.integer :custom_field_id
      t.integer :field_type_id
      t.string :descr
      t.integer :label_id

      t.timestamps
    end
  end

  def self.down
    drop_table :custom_fields
  end
end
