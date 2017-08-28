class CreateTableReportRequestRows < ActiveRecord::Migration
  def self.up
      create_table :report_request_rows, :force => true do |t|
      t.integer :report_request_row_id
      t.integer :row_id
      t.integer :report_request_id

      t.timestamps
    end

    add_index :report_request_rows, [:report_request_row_id], :name => "IX_report_request_rows_report_request_row_id"
    add_index :report_request_rows, [:row_id], :name => "IX_report_request_rows_row_id"
    add_index :report_request_rows, [:report_request_id], :name => "IX_report_request_rows_report_request_id"
  end

  def self.down
    drop_table :report_request_rows
  end
end
