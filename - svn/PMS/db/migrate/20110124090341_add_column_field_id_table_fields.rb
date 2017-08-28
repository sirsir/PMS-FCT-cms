class AddColumnFieldIdTableFields < ActiveRecord::Migration
  def self.up
    add_column(:fields,:field_id, :integer)
  end

  def self.down
    remove_column(:fields,:field_id)
  end
end
