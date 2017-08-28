class CustomFields::DateTimeRange < CustomField

  class << self
    def create_date_time_range_value(cell, date_time_range)
      Cells::DateTimeRangeValue.create(:cell_id => cell.id,
        :date_time_from => date_time_range[:from].to_date, :date_time_to => date_time_range[:to].to_date)
    end
  end # end class self

  def description
    'DateTimeRange'
  end

  #   custom_field.format_date -> symbol
  # Get date format
  #   custom_field.format_date #=> :short_date
  def format_date
    self[:value]  ||= {}
    self[:value][:format_date] ||= :short_date
    self[:value][:format_date].to_sym
  end

  #   custom_field.defualt_value -> string
  # Get default value
  #   custom_field.default_value #=> "current_date"
  def default_value
    self[:value] ||= {}
    self[:value][:default_value] ||= 'empty'
    self[:value][:default_value]
  end

  #   custom_field.html(cell) -> string
  # Get string to display in screen
  #   custom_field.html(cell) #=> "From: 01/01/2001 - To: 01/04/2005"
  def html(cell)
    cell_date_time_range = cell.date_time_range_value
    return 'From: - To:' if cell_date_time_range.nil?
    dt_format = format_date
    date_time_range_values = [cell_date_time_range.date_time_from.to_date, cell_date_time_range.date_time_to.to_date] if cell_date_time_range
    results = [date_time_range_values].flatten.compact.collect do |dv|
      case dt_format
      when :half_year then
        s_year = dv.year.to_s

        period = CustomFields::DateTimeField.half_year(dv)
        s_date = case period
                 when 1 then '1st Half,' + s_year
                 else '2nd Half,' + s_year
        end
      when :quarter_year then
        s_year = dv.year.to_s

        period = CustomFields::DateTimeField.quarter_year(dv)
        s_date = case period
                 when 1 then '1st Quarter,' + s_year
                 when 2 then '2nd Quarter,' + s_year
                 when 3 then '3rd Quarter,' + s_year
                 else '4th Quarter,' + s_year
                 end
      else
        s_date = CustomFields::DateTimeFormat.strf_date(dt_format, dv)
      end

      s_date unless dv == Date.null_date
    end

    "From: #{results[0]} - To: #{results[1]}" if results.any?{|dv| !dv.nil? }
  end

  #   custom_field.text(value) -> string
  # Get string to display in screen
  #   custom_field.text({}) #=> ""
  #   custom_field.text(nil) #=> ""
  #   custom_field.text('') #=> ""
  #   custom_field.text({:form => '01/01/2001', :to => '01/04/2005'}) #=> From: 2000-01-01 - To: 2005-01-04
  def text(value)
    return '' if value.to_s.empty?
    
    if value.is_a?(Hash)
      "From: #{value[:from].to_date} - To: #{value[:to].to_date}"
    else
      dt_value = value.to_date
      dt_format = format_date
      case dt_format
      when :half_year then
        s_year = dt_value.year.to_s

        period = CustomFields::DateTimeField.half_year(dt_value)
        s_date = case period
                 when 1 then '1st Half,' + s_year
                 else '2nd Half,' + s_year
                 end
      when :quarter_year then
        s_year = dt_value.year.to_s

        period = CustomFields::DateTimeField.quarter_year(dv)
        s_date = case period
                 when 1 then '1st Quarter,' + s_year
                 when 2 then '2nd Quarter,' + s_year
                 when 3 then '3rd Quarter,' + s_year
                 else '4th Quarter,' + s_year
                 end
      else
        s_date = CustomFields::DateTimeFormat.strf_date(dt_format,dt_value)
      end
      return s_date
    end
  end

  def parse(value, options={})
    #~ ToDo: A from~to range is required
    super
  end

  def search_value?(cell, filter)
    return true if filter.nil?

    date_time_range_from = cell.date_time_range_value.date_time_from.to_s.to_date
    date_time_range_to = cell.date_time_range_value.date_time_to.to_s.to_date
    null_date = Date.null_date

    if filter['status'] == 'not_set'
      return date_time_range_from == null_date && date_time_range_to == null_date
    else
      filter_from = (filter[:from].to_s.empty?) ?  null_date : filter[:from].to_date
      filter_to = (filter[:to].to_s.empty?) ? null_date : filter[:to].to_date

      case
        when date_time_range_from == null_date && date_time_range_to == null_date then
          filter_to == null_date && filter_from == null_date
      when filter_to == null_date then
          return true if filter_from == null_date
          filter_from <= date_time_range_to || date_time_range_to == null_date
      when filter_from == null_date then
        filter_to >= date_time_range_from 
      else
        !((filter_from > date_time_range_to unless date_time_range_to == null_date) || (filter_to < date_time_range_from))
      end
    end
  end
end