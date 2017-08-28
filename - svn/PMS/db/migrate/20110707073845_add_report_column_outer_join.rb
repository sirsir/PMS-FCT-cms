class AddReportColumnOuterJoin < ActiveRecord::Migration
  def self.up
    add_column :reports, :reference_screen_outer_joins, :yaml

    reports = Report.find(:all)
    reports.each do |r|
      r.reference_screen_outer_joins = []

      r.reference_screen_outer_joins = r.reference_screens.collect{|s| {"-1" => "false"} }
      
      r.save
    end
  end

  def self.down
    remove_column :reports, :reference_screen_outer_joins
  end
end
