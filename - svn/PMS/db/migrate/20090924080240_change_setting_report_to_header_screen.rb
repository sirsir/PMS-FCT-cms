class ChangeSettingReportToHeaderScreen < ActiveRecord::Migration
  def self.up
    report_screen = Screen.from_action(:controller=>"reports", :action=>"index")
    report_screen[:type] = "HeaderScreen"
    report_screen.save
  end

  def self.down
    report_screen = Screen.from_action(:controller=>"reports", :action=>"index")
    report_screen[:type] = "ListScreen"
    report_screen.save
  end
end
