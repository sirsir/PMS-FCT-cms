class AddColumnReportTemplateFile < ActiveRecord::Migration
  def self.up
    add_column :report_templates, :file, :string, :default => :none
  end

  def self.down
    remove_column :report_templates, :file
  end
end
