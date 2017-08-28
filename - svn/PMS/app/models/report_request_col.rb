class ReportRequestCol < ActiveRecord::Base
  belongs_to :report_request
  belongs_to :fields_report

  belongs_to :report_request_col
  has_many :report_request_cols, :include => [:report_request_cols], :dependent => :destroy

  has_many :report_request_cells , :dependent => :destroy

  alias_attribute :parent ,:report_request_col
  alias_attribute :childs ,:report_request_cols

  class << self
    def purge(report_request_id)
      conn = ActiveRecord::Base.connection
      conn.delete <<SQL_CMD
DELETE FROM report_request_cols WHERE report_request_id = #{report_request_id}
SQL_CMD
    end
  end

  def column_span(cached_report_request = nil)
    @column_span ||= begin
      cached_report_request ||= report_request

      percentage_weight_column_span = childs.collect{|c| c.fields_report.percentage_weight_col_span }.compact.sum      
      percentage_weight_column_span = 1 if cached_report_request.report.cell_location == :row && percentage_weight_column_span > 1

      last_level = !cached_report_request.report.col_fields_report_ids.include?(fields_report_id) ||
        cached_report_request.report.col_fields_report_ids.last == fields_report_id
      
      if last_level && cached_report_request.report.cell_location == :row
        child_column_span = 1
      else
        child_column_span = childs.collect{|c| c.column_span(cached_report_request) }.sum
      end
      child_column_span += percentage_weight_column_span

      cell_fields_reports = cached_report_request.report.cell_fields_reports

      cell_field_report_count = (cached_report_request.report.cell_location == :row) ? 1 : cell_fields_reports.size

      percentage_weight_cell_fields_reports_length = 
        if cached_report_request.report.cell_location == :col
          cell_fields_reports[0..cell_field_report_count-1].collect{|c| c.percentage_weight_col_span }.compact.sum
        else
          cached_report_request.report.has_percentage_weight? ? 1 : 0
        end
      cell_fields_reports_length = cell_fields_reports[0..cell_field_report_count-1].length + percentage_weight_cell_fields_reports_length
      cell_fields_reports_length -= cell_fields_reports_length if !last_level && self.fields_report.summarize == :non

      [child_column_span, 1].max + (last_level ? 0 : cell_fields_reports_length )
    end
  end
  
  def full_descr
    unless @full_descr
      fs = []
      fs << [self.parent.full_descr] unless self.parent.nil?
      fs << [self.descr]

      @full_descr = fs.join(' - ')
    end
    
    @full_descr
  end

  def each_col_array
     fs = []
     fs << [self.parent.each_col_array] unless self.parent.nil?
     fs << [self]
     fs
  end

  def leaf_report_request_cols(filter_date_src_year = false)
    unless @leaf_report_request_cols
      if childs.empty?
        @leaf_report_request_cols = [self]
      else
        year_month = CustomFields::DateTimeField.month(:year) if filter_date_src_year
        @leaf_report_request_cols = childs.select{|c| !filter_date_src_year || !c.is_a?(ReportRequestCols::DateSrc) || c.source_id == year_month}.collect{|c| c.leaf_report_request_cols(filter_date_src_year) }.flatten
      end
    end

    @leaf_report_request_cols
  end

  def grand_total_value
    @grand_total_value ||= begin
      cell_values = self.leaf_report_request_cols.collect do |rrc|
        rrc.report_request_cells.collect{|c| c.value }
      end.flatten
      
      ReportRequestCell.evaluate(cell_values)
    end
  end

  def date_src_report_request_col
    rr_col = self
    case rr_col
    when ReportRequestCols::DateSrc
      rr_col
    else
      if rr_col.nil? || rr_col.parent.nil?
        nil
      else
        rr_col.parent.date_src_report_request_col
      end
    end
  end
  
  validates_presence_of :fields_report_id
end
