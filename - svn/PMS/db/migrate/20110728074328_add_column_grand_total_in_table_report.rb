class AddColumnGrandTotalInTableReport < ActiveRecord::Migration
  def self.up
    add_column :reports, :grand_total, :string
    reports = Report.find(:all)
    reports.each do |report|
      report.grand_total = ["row","col"]
      report.save
    end
  end

  def self.down
    remove_column :reports, :grand_total
  end
end
