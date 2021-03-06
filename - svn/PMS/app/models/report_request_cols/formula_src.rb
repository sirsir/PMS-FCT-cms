module ReportRequestCols
  class FormulaSrc < ReportRequestCol
    belongs_to :fields_report, :foreign_key => 'source_id'

    def description
      @description ||= fields_report.descr.to_s.clone
    end

    alias_method :descr, :description

    def evaluate_value(row, options = {})
      options[:data_type] = fields_report.format_data_type
      options[:report_request_cols] = ( self.parent.nil? ) ? [self] : self.parent.childs.select{|c| c[:id] != self[:id]}
      
      row.field_cache[self[:id]] ||= Fields::Formula.evaluate_value(fields_report.formula, row, {}, options)
    end

  end
end