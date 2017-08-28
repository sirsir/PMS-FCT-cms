class CreateFieldReportFilters < ActiveRecord::Migration
  def self.up
    create_table :field_report_filters do |t|
      t.integer :report_id
      t.integer :field_id
      t.yaml :value
      
      t.timestamps
    end
    add_index :field_report_filters, [:report_id], :name => "IX_field_report_filters_request_id"
    add_index :field_report_filters, [:field_id], :name => "IX_field_report_filters_field_id"
  end

  def self.down
    drop_table :field_report_filters
  end
end
