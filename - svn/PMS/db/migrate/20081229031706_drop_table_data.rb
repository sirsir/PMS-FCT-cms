class DropTableData < ActiveRecord::Migration
  def self.up
	  drop_table :datas
  end

  def self.down
	  create_table :datas do |t|
		  t.integer :row_id
		  t.integer :field_id
		  t.string :value
		  
		  t.timestamps
	  end
  end
end
