class AddColumnRowIdTbRows < ActiveRecord::Migration
  def self.up
    add_column(:rows,:row_id,:integer)
  end

  def self.down
    remove_column(:rows,:row_id)
  end
end
