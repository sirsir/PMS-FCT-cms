class Cells::CalendarValue < ActiveRecord::Base
  belongs_to :cell
  belongs_to :row

  alias_attribute :detail_row, :row
  
  def before_destroy
    row.destroy
  end

  def date_time
    self[:date_time].localtime
  end
end
