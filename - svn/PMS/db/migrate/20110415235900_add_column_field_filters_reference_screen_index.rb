class AddColumnFieldFiltersReferenceScreenIndex < ActiveRecord::Migration
  def self.up
    add_column :field_filters, :reference_screen_index, :integer

    field_filters = FieldFilter.find(:all)
    field_filters.each do |ff|
      reference_screen_ids = ff.report_request.report.reference_screen_ids
      ff.reference_screen_index = 0
      ff.reference_screen_index = reference_screen_ids.index(ff.field.screen_id).to_i if ff.field
      ff.save
    end
  end

  def self.down
    remove_column :field_filters, :reference_screen_index
  end
end
