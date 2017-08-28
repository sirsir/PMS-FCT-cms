class CreateDetailRows < ActiveRecord::Migration
  def self.up
    create_table :detail_rows do |t|
      t.integer :row_id
      t.integer :header_row_id

      t.timestamps
    end
  end

  def self.down
    drop_table :detail_rows
  end
end
