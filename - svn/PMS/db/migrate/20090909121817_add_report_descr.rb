class AddReportDescr < ActiveRecord::Migration
  def self.up
    add_column :reports, :descr, :string, :size=>50
  end

  def self.down
    remove_column :reports, :descr
  end
end
