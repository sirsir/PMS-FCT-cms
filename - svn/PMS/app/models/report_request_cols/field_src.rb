module ReportRequestCols
  class FieldSrc < ReportRequestCol
    belongs_to :fields_report, :foreign_key => 'source_id'

    def description
      @description ||= fields_report.descr.to_s.clone
    end

    alias_method :descr, :description

  end
end