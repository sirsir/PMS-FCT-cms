class RemoveColumnMadatoryCheck < ActiveRecord::Migration
  def self.up
	remove_column :fields, :madatory_check
	add_column :fields, :mandatory_check, :integer
  end

  def self.down
	add_column :fields, :madatory_check, :integer
	remove_column :fields, :mandatory_check	
  end
end
