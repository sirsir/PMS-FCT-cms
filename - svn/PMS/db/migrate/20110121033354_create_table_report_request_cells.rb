class CreateTableReportRequestCells < ActiveRecord::Migration
def self.up
      create_table :report_request_cells, :force => true do |t|
      t.integer :report_request_row_id
      t.integer :report_request_col_id
      t.yaml :value

      t.timestamps
    end

    add_index :report_request_cells, [:report_request_row_id], :name => "IX_report_request_cells_report_request_row_id"
    add_index :report_request_cells, [:report_request_col_id], :name => "IX_report_request_cells_report_request_col_id"
  end

  def self.down
    drop_table :report_request_cells
  end
end
