class AddFieldsReportsFieldTypeColumn < ActiveRecord::Migration
  def self.up
    add_column :fields_reports, :field_type, :string
    add_column :fields_reports, :formula, :yaml

    fields_reports = FieldsReport.find(:all)
    fields_reports.each do |fr|
      fr.field_type = "field"

      fr.save
    end
  end

  def self.down
    remove_column :fields_reports, :field_type
    remove_column :fields_reports, :formula
  end
end
