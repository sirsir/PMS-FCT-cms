class AddColumnPerPageInUser < ActiveRecord::Migration
  def self.up
    add_column :users, :per_page, :integer
  end

  def self.down
	  remove_column :users, :per_page
  end
end
