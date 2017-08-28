class AddColumnFieldsReportsLabelId < ActiveRecord::Migration
  def self.up
    add_column :fields_reports, :label_id, :integer
  end

  def self.down
    remove_column :fields_reports, :label_id
  end
end
