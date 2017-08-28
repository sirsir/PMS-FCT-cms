class AddColumnRemarkInRows < ActiveRecord::Migration
   def self.up
	   add_column :rows, :remark, :string
   end
   
   def self.down
	   remove_column :rows, :remark
   end
end
