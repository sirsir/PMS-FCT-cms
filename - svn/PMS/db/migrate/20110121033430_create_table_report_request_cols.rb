class CreateTableReportRequestCols < ActiveRecord::Migration
 def self.up
      create_table :report_request_cols, :force => true do |t|
      t.integer :report_request_col_id
      t.integer :source_id
      t.integer :fields_report_id
      t.string  :type

      t.timestamps
    end

    add_index :report_request_cols, [:report_request_col_id], :name => "IX_report_request_cols_report_request_col_id"
    add_index :report_request_cols, [:source_id], :name => "IX_report_request_cols_source_id"
    add_index :report_request_cols, [:fields_report_id], :name => "IX_report_request_cols_fields_report_id"
  end

  def self.down
    drop_table :report_request_cols
  end
end
