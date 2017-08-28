class CreateLogs < ActiveRecord::Migration
  def self.up
    create_table :full_logs do |t|
      t.integer :row_id
      t.integer :seq_no
      t.yaml :action
      t.string :user
      t.yaml :value

      t.timestamps
    end

    remove_column :rows, :log
  end

  def self.down
    add_column :rows, :log, :yaml

    drop_table :full_logs
  end
end
