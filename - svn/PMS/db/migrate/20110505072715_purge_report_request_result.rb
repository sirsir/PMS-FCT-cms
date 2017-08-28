class PurgeReportRequestResult < ActiveRecord::Migration
  def self.up
    report_requests = ReportRequest.find(:all)
    report_requests.each do |rr|
      rr.purge
      
      rr.last_run_at = nil

      rr.save
    end
  end

  def self.down
  end
end
