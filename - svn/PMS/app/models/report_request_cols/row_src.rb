module ReportRequestCols
  class RowSrc < ReportRequestCol
    belongs_to :row, :foreign_key => 'source_id'

    def description
      @description ||= row.description.clone
    end

    alias_method :descr, :description

  end
end