class Date
  class << self
#    def date_part(part, d1, d2)
#      hours,minutes,seconds,frac = Date.day_fraction_to_time(d2 - d1)
#      i = [:hours, :minutes, :seconds, :frac].index(part)
#      [hours,minutes,seconds,frac][i]
#    end

    #   Date.null_date  -> date
    # Return the null_date set in the loaded Rails environment configuration file
    #   Date.null_date  #=> Mon, 01 Jan 2000
    def null_date
      @@null_date ||= Date.strptime(Rails.configuration.null_date, '%Y/%m/%d')
    end
    
    #   Date.from_dmy(date) -> date
    # Flip the, possible, date from 'dd/mm/yyyy' to 'yyyy/mm/dd', then cast it to a
    # date value
    #   Date.from_dmy('01/02/2003') #=> Sat, 01 Feb 2003
    #   Date.from_dmy('01-02-2003') #=> Sat, 01 Feb 2003
    #   Date.from_dmy('')           #=> Mon, 01 Jan 2000
    #   Date.from_dmy(nil)          #=> Mon, 01 Jan 2000
    def from_dmy(date)
      date.to_s.gsub(/^(\d{2})[\/-](\d{2})[\/-](\d{4})/, '\3/\2/\1').to_date
    end
  end

  #   Time.to_date  -> date
  # Get the date part of the time object
  #   t = Time.null_datetime  #=> Sat Jan 01 00:00:00 +0700 2000
  #   t.to_date               #=> Sat, 01 Jan 2000
  def to_datetime
    DateTime.parse(self.to_s)
  end
end
#
#class DateTime
#  class << self
#
#    #   DateTime.null_datetime  -> datetime
#    # Return the null_date set in the loaded Rails environment configuration file
#    #   Date.null_date  #=> Mon, 01 Jan 2000
#    def null_datetime
#      @@null_datetime ||= DateTime.parse(Date.null_date.to_s)
#    end
#  end
#
#  #   Time.to_date  -> date
#  # Get the date part of the time object
#  #   t = Time.null_datetime  #=> Sat Jan 01 00:00:00 +0700 2000
#  #   t.to_date               #=> Sat, 01 Jan 2000
#  def to_datetime
#    Date.parse(self.to_s)
#  end
#
#end


# ToDo: include the well recommended gem into the system
#
#  require 'chronic'
#  Time.now # => Fri Jul 25 00:00:25 0200 2008
#  Chronic.parse 'tomorrow 8 in the evening'  # => Sat Jul 26 20:00:00 0200 2008
#  Chronic.parse 'next Monday noon'           # => Mon Jul 28 12:00:00 0200 2008
#  Chronic.parse 'first Wednesday of Aug'     # => Wed Aug 06 12:00:00 0200 2008
#  Chronic.parse 'first Wednesday of Aug 7pm' # => Wed Aug 06 19:00:00 0200 2008
