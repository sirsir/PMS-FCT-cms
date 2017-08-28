class AddScreenPrintFields < ActiveRecord::Migration
  def self.up
    add_column :screens, :page_size, :string, :default => 'A4'
    add_column :screens, :page_layout, :string, :default => 'portrait'
  end

  def self.down
    remove_column :screens, :page_size
    remove_column :screens, :page_layout
  end
end
