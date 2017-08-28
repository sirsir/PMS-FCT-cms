class AddReportsReferenceScreenIds < ActiveRecord::Migration
  def self.up
    add_column :reports, :reference_screen_ids, :yaml
  end

  def self.down
    remove_column :reports, :reference_screen_ids
  end
end
