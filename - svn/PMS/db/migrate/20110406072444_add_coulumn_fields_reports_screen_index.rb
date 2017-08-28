class AddCoulumnFieldsReportsScreenIndex < ActiveRecord::Migration
  def self.up
    add_column :fields_reports, :reference_screen_index, :integer

    fields_reports = FieldsReport.find(:all)
    fields_reports.each do |fr|
      reference_screen_ids = fr.report.reference_screen_ids
      fr.reference_screen_index = 0
      fr.reference_screen_index = reference_screen_ids.index(fr.field.screen_id).to_i if fr.field
      fr.save
    end
  end

  def self.down
    remove_column :fields_reports, :reference_screen_index
  end
end
