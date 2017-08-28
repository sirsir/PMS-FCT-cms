class CreateReportTemplates < ActiveRecord::Migration
  def self.up
    create_table :report_templates do |t|
      t.integer :screen_id
      t.string :name
      t.string :func

      t.timestamps
    end
  end

  def self.down
    drop_table :report_templates
  end
end
