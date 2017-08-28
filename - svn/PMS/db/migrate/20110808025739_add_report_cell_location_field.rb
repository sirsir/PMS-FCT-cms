class AddReportCellLocationField < ActiveRecord::Migration
  def self.up
    add_column :reports, :cell_location, :string
    reports = Report.find(:all)
    reports.each do |report|
      report.cell_location = "col"
      
      report.save
    end
  end

  def self.down
    remove_column :reports, :cell_location
  end
end
