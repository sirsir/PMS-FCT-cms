module ReportRequestCols
  class DateSrc < ReportRequestCol

    def description
      @description ||= CustomFields::DateTimeField.month_description(self.source_id)
    end

    alias_method :descr, :description

  end
end
