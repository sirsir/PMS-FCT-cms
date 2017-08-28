class ChangeReportRequestAction < ActiveRecord::Migration
  def self.up
    report_request_screen = Screen.find(:first, :conditions => { :screens => { :name => "Report Requests"}})

    unless report_request_screen
      reports_screen = Screen.find(:first, :conditions => { :screens => { :name => "Reports"}})
      report_request_label = Label.find(:first, :conditions => { :labels => { :name => "S_Report_Requests"}})
      
      report_request_screen = Screen.new(
          :name => "Report Requests",
          :system => 1,
          :screen_id => reports_screen.id,
          :label_id => report_request_label.id
        )
    end

    report_request_screen.controller = "report_requests"
    report_request_screen.action = "index"
    
    report_request_screen.save
  end

  def self.down
    report_request_screen = Screen.find(:first, :conditions => { :screens => { :name => "Report Requests"}})

    report_request_screen.controller = "screens"
    report_request_screen.action = "show"

    report_request_screen.save
  end
end
