class ChangeReportRequestLastRunFieldToDateTime < ActiveRecord::Migration
  def self.up
    change_column :report_requests, :last_run_at, :datetime
  end

  def self.down
    change_column :report_requests, :last_run_at, :date
  end
end
