class AddColumnReportTemplateOutputType < ActiveRecord::Migration
  def self.up
    add_column :report_templates, :output_type, :string, :default => 'pdf'
  end

  def self.down
    remove_column :report_templates, :output_type
  end
end
