class CreateReportRequests < ActiveRecord::Migration
  def self.up
    create_table :report_requests do |t|
      t.string :name
      t.integer :report_id
      t.integer :user_id
      t.string :remark

      t.timestamps
    end
  end

  def self.down
    drop_table :report_requests
  end
end
