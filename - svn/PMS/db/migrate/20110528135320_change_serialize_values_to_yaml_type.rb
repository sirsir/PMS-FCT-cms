class ChangeSerializeValuesToYamlType < ActiveRecord::Migration
  def self.up
    change_column :cells, :value, :yaml
    
    change_column :custom_fields, :value, :yaml
    change_column :custom_fields, :display_flags, :yaml
    
    change_column :fields, :value, :yaml
    change_column :fields, :display_flags, :yaml
    change_column :fields, :sorting_order, :yaml
    
    change_column :fields_reports, :field_format, :yaml
    
    change_column :field_filters, :value, :yaml
    
    change_column :field_report_filters, :value, :yaml
    
    change_column :full_logs, :action, :yaml
    change_column :full_logs, :value, :yaml

    change_column :permissions, :actions, :yaml

    change_column :reports, :reference_screen_ids, :yaml
    change_column :reports, :reference_screen_alias, :yaml
    change_column :reports, :criterias, :yaml

    change_column :report_request_cells, :value, :yaml

    change_column :rows, :remark, :yaml
    change_column :rows, :value, :yaml

    change_column :screens, :value, :yaml
  
    change_column :sessions, :data, :yaml
  end

  def self.down
  end
end
