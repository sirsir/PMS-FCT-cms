class AddColumnMandatoryCheckInField < ActiveRecord::Migration
  def self.up
	  add_column :fields, :madatory_check, :integer
  end
  
  def self.down
	  remove_column :fields, :madatory_check
  end
end
