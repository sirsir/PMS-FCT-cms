class CreateCell < ActiveRecord::Migration
  def self.up
    create_table :cells do |t|
      t.integer :row_id
      t.integer :field_id
      t.yaml :value
  
      t.timestamps
    end
  end

  def self.down
    drop_table :cells
  end
end
