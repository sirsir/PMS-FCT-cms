class AddColumnReportTemplateDisplay < ActiveRecord::Migration
  def self.up
    add_column :report_templates, :display, :string, :default => 'edit'
  end

  def self.down
    remove_column :report_templates, :display
  end
end
