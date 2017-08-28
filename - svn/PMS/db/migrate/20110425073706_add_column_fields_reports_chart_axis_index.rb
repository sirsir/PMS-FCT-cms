class AddColumnFieldsReportsChartAxisIndex < ActiveRecord::Migration
  def self.up
    add_column :fields_reports, :chart_axis_index, :integer
    
    fields_reports = FieldsReport.find(:all)
    fields_reports.each do |fr|
      fr.chart_axis_index = FieldsReport.chart_axises.index(:none)

      fr.save
    end
  end

  def self.down
    remove_column :fields_reports, :chart_axis_index
  end
end
