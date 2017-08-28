class AddColumnReportRequestRowsReferenceScreenIndex < ActiveRecord::Migration
  def self.up
    add_column :report_request_rows, :reference_screen_index, :integer

    report_request_rows = ReportRequestRow.find(:all)
    report_request_rows.each do |rr_r|
      reference_screen_ids = rr_r.report_request.report.reference_screen_ids
      rr_r.reference_screen_index = 0
      rr_r.reference_screen_index = reference_screen_ids.index(rr_r.row.screen_id).to_i
      rr_r.save
    end
  end

  def self.down
    remove_column :report_request_rows, :reference_screen_index
  end
end
