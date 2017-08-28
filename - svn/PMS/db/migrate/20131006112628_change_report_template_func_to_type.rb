class ChangeReportTemplateFuncToType < ActiveRecord::Migration
  def self.up
    report_templates = ReportTemplate.find(:all)

    report_templates.each do |rt|
      rt.func = "ReportTemplates::#{rt.func.classify}"

      rt.save
    end

    rename_column :report_templates, :func, :type
  end

  def self.down
    rename_column :report_templates, :type, :func

    report_templates = ReportTemplate.find(:all)

    report_templates.each do |rt|
      rt.func = rt.func.gsub('ReportTemplates::', '').underscore

      rt.save
    end

  end
end
