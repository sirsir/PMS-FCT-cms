class AddColumnFieldReportFiltersReferenceScreenIndex < ActiveRecord::Migration
  def self.up
    add_column :field_report_filters, :reference_screen_index, :integer

    field_report_filters = FieldReportFilter.find(:all)
    field_report_filters.each do |frf|
      reference_screen_ids = frf.report.reference_screen_ids
      frf.reference_screen_index = 0
      frf.reference_screen_index = reference_screen_ids.index(frf.field.screen_id).to_i if frf.field
      frf.save
    end
  end

  def self.down
    remove_column :field_report_filters, :reference_screen_index
  end
end
