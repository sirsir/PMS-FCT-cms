class CreateCellsCalendarValues < ActiveRecord::Migration
  def self.up
    create_table :calendar_values do |t|
      t.integer :cell_id
      t.datetime :date_time
      t.integer :row_id
      t.timestamps
    end

    add_index :calendar_values, [:cell_id, :date_time], :name => "IX_calendar_values_cell_id_date_time"
    add_index :calendar_values, [:cell_id], :name => "IX_calendar_values_cell_id"
  end

  def self.down
    drop_table :calendar_values
  end
end
