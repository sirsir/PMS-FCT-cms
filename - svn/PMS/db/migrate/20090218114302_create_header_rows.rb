class CreateHeaderRows < ActiveRecord::Migration
  def self.up
    create_table :header_rows do |t|
      t.integer :row_id
      
      t.timestamps
    end
  end

  def self.down
    drop_table :header_rows
  end
end
