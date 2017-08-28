module ReportRequestCols
  class LabelSrc < ReportRequestCol
    belongs_to :label, :foreign_key => 'source_id'

    def description
      @description ||= label.descr.clone
    end

    alias_method :descr, :description

  end
end