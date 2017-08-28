class CreateDateTimeRangeValues < ActiveRecord::Migration
  def self.up
    create_table :date_time_range_values do |t|
      t.integer :cell_id
      t.datetime :date_time_from
      t.datetime :date_time_to
      t.timestamps
    end

    add_index :date_time_range_values, [:cell_id], :name => "IX_date_time_range_values_cell_id"
  end

  def self.down
    drop_table :date_time_range_values
  end
end
