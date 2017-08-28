class CreateFieldsReports < ActiveRecord::Migration
  def self.up
    create_table( :fields_reports, :id => false) do |t|
      t.integer :field_id, :null => false
      t.integer :report_id, :null => false

      t.timestamps
    end
	
	execute "
ALTER TABLE dbo.fields_reports ADD CONSTRAINT
	PK_fields_reports PRIMARY KEY CLUSTERED 
	(
	field_id,
	report_id
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	
	"
  end

  def self.down
    drop_table :fields_reports
  end
end
