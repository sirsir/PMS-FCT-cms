class ReportRequestCell < ActiveRecord::Base
  belongs_to :report_request_row
  belongs_to :report_request_col

  serialize :value
  
  class << self
    def purge(report_request_row_ids)
      report_request_row_ids = (report_request_row_ids + [-1]).join(',')

      conn = ActiveRecord::Base.connection
      conn.delete <<SQL_CMD
DELETE FROM report_request_cells WHERE report_request_row_id IN (#{report_request_row_ids})
SQL_CMD
    end

    def evaluate(cell_value)
      cell_value ||= []
      
      case cell_value
      when Array
        merge_cell_value = {
          :summarize => cell_value.empty? ? :none : cell_value.first[:summarize],
          :values => cell_value.collect{|v| v[:values] }.flatten
        }
        evaluate(merge_cell_value)
      else
        cell_value[:values] = [cell_value[:values]].flatten
        cell_value[:values].compact!
        case cell_value[:summarize]
        when :non then
          cell_value[:values]
        when :cnt then
          cell_value[:values].uniq.size
        when :sum then
          cell_value[:values].collect{|e| e.to_f }.sum
        when :avg then
          cell_value[:values].collect{|e| e.to_f }.sum / cell_value[:values].size unless cell_value[:values].empty?
        when :min then
          cell_value[:values].min
        when :max then
          cell_value[:values].max
        when :per then
          ( cell_value[:grand_total_value].to_f != 0.0 ) ?  (cell_value[:value].to_f / cell_value[:grand_total_value].to_f) * 100 : 0
        when :grp
          cell_value[:values].first
        when :unq
          cell_value[:values].uniq
        end
      end
    end
    
    #~ Compact the values for summarizes the don't need the details
    def compact(cell_value)
      case cell_value[:summarize]
      when :cnt then
        cell_value[:values].uniq!
      when :sum then
        cell_value[:values] = [cell_value[:values].collect!{|e| e.to_f }.sum]
      when :min then
        cell_value[:values] = [cell_value[:values].min]
      when :max then
        cell_value[:values] = [cell_value[:values].max]
      when :grp
        cell_value[:values] = [cell_value[:values].first]
      end
    end
  end

  def description

  end

  validates_presence_of :report_request_row_id
  validates_presence_of :report_request_col_id
end