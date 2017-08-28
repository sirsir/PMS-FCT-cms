class AddColumnReportCriterias < ActiveRecord::Migration
  def self.up
    add_column :reports, :criterias, :yaml
    add_column :reports, :reference_screen_alias, :yaml
    add_column :reports, :remark, :string

    reports = Report.find(:all)
    reports.each do |r|
      r.criterias = []
      r.reference_screen_alias = []

      r.reference_screens.each do |s|
        a = s.label_descr.gsub(/[^A-Z]/,'').downcase
        a << "_#{r.reference_screen_alias.select{|x| x =~ Regexp.new("(^#{a}$|^#{a}_[0-9]+$)") }.length}" if r.reference_screen_alias.include?(a)
        r.reference_screen_alias << a
      end

      r.remark = ""
      
      r.save
    end
  end

  def self.down
    remove_column :reports, :remark
    remove_column :reports, :reference_screen_alias
    remove_column :reports, :criterias
  end
end
