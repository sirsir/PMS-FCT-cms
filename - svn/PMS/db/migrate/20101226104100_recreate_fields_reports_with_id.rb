class RecreateFieldsReportsWithId < ActiveRecord::Migration
  def self.up
    drop_table :fields_reports

    create_table :fields_reports do |t|
      t.integer :field_id, :null => false
      t.integer :report_id, :null => false
      t.integer :seq_no, :null => false
      t.boolean :group_flag
      t.boolean :sub_total_flag

      t.timestamps
    end

    [:report_id, :field_id].each do |f|
      add_index :fields_reports, [f], :name => "IX_fields_reports_#{f}"
    end
  end

  def self.down
    drop_table :fields_reports
    
    create_table( :fields_reports, :id => false) do |t|
      t.integer :field_id, :null => false
      t.integer :report_id, :null => false

      t.timestamps
    end

    add_index :fields_reports, [:report_id, :field_id], :unique => true
  end
end
