class CreateFieldFilters < ActiveRecord::Migration
  def self.up
    create_table :field_filters do |t|
      t.integer :report_request_id
      t.integer :field_id
      t.yaml :value

      t.timestamps
    end

    add_index :field_filters, [:report_request_id], :name => "IX_field_filters_report_request_id"
    add_index :field_filters, [:field_id], :name => "IX_field_filters_field_id"
  end

  def self.down
    drop_table :field_filters
  end
end
