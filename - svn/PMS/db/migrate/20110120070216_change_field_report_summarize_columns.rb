class ChangeFieldReportSummarizeColumns < ActiveRecord::Migration
  def self.up
    remove_column :fields_reports, :group_flag
    remove_column :fields_reports, :sub_total_flag

    add_column :fields_reports, :summarize, :string
    add_column :fields_reports, :location, :string
  end

  def self.down
    remove_column :fields_reports, :location
    remove_column :fields_reports, :summarize

    add_column :fields_reports, :group_flag, :boolean
    add_column :fields_reports, :sub_total_flag, :boolean
  end
end
