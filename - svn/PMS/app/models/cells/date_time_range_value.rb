class Cells::DateTimeRangeValue < ActiveRecord::Base
  belongs_to :cell

  def date_time_from
    return '' if self[:date_time_from].to_s.empty? || self[:date_time_from].to_time.localtime.to_date == Date.null_date
    self[:date_time_from].localtime
  end

  def date_time_to
    return '' if self[:date_time_to].to_s.empty? || self[:date_time_to].to_time.localtime.to_date == Date.null_date
    self[:date_time_to].localtime
  end
end
