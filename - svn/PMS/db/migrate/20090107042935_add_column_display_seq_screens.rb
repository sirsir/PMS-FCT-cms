class AddColumnDisplaySeqScreens < ActiveRecord::Migration
  def self.up
    add_column :screens,:display_seq,:integer
  end

  def self.down
    remove_column :screens,:display_seq
  end
end
