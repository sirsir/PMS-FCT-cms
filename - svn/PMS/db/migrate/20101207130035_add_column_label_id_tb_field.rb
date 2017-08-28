class AddColumnLabelIdTbField < ActiveRecord::Migration
  def self.up
    add_column(:fields, :label_id,:integer)
  end

  def self.down
    remove_column(:fields, :label_id )
  end
end
