class AddColFormatTbFieldReport < ActiveRecord::Migration
  def self.up
    add_column :fields_reports, :field_format, :yaml
  end

  def self.down
    remove_column(:fields_reports, :field_format )
  end
end
