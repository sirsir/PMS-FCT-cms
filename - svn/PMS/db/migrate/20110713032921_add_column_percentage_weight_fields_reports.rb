class AddColumnPercentageWeightFieldsReports < ActiveRecord::Migration
  def self.up
    add_column :fields_reports, :percentage_weight, :yaml
    
    fields_reports = FieldsReport.find(:all)
    fields_reports.each do |fr|
      fr.percentage_weight = {"-1" => "false"}

      fr.save
    end
  end

  def self.down
    remove_column :fields_reports, :percentage_weight
  end
end
