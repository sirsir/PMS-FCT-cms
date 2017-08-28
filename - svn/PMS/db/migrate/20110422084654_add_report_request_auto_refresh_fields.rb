class AddReportRequestAutoRefreshFields < ActiveRecord::Migration
  def self.up
    add_column :report_requests, :refresh_interval_index, :integer
    add_column :report_requests, :last_run_at, :date

    report_requests = ReportRequest.find(:all)
    report_requests.each do |rr|
      rr.refresh_interval_index = ReportRequest.refresh_intervals.index(:every_day)
      rr.last_run_at =  Date.null_date

      rr.save
    end
  end

  def self.down
    remove_column :report_requests, :refresh_interval_index
    remove_column :report_requests, :last_run_at
  end
end
