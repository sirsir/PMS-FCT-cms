class AddColumnReportRequestIdTbReportRequestColumn < ActiveRecord::Migration
  def self.up
    add_column(:report_request_cols, :report_request_id, :integer)
  end

  def self.down
    drop_column(:report_request_cols, :report_request_id)
  end
end
