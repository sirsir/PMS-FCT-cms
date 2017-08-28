class ChangeValueFieldTypeToText < ActiveRecord::Migration
  def self.up
    tables.each do |t|
      change_column t, :value, :yaml
    end
  end

  def self.down
    tables.each do |t|
      change_column t, :value, :string
    end
  end
  
  def self.tables
    [:fields, :custom_fields]
  end
end
