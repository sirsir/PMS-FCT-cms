class AddScreenType < ActiveRecord::Migration
  def self.up
	  add_column :screens, :type, :string
  end

  def self.down
	  remove_column :screens, :type
  end
end
