class AddColumnSortingIndexInTableFieldReport < ActiveRecord::Migration
  def self.up
    add_column :fields_reports, :sorting_index, :integer

    fields_reports = FieldsReport.find(:all)
    fields_reports.each do |fr|
      fr.sorting_index = FieldsReport.sortings.index(:none)

      fr.save
    end
  end

  def self.down
    remove_column :fields_reports, :sorting_index
  end
end
