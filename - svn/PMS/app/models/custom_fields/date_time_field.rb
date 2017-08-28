# Stored value structure
#
# <b>CustomField</b>
#   custom_field.value = {
#       :format_date => :short_date / :long_date / :short_month / :long_month / :year / :quarter_year / :half_year
#       :format_time => :none / :hour / :minute / :second
#     }
#
# <b>Field</b>
#   field.value = nil
#
# <b>Cell</b>
#   cell.value = 2009/02/28

class CustomFields::DateTimeField < CustomField

  class << self
    #   CustomFields::DateTimeField.name_prefix -> string
    #
    # Get the default name prefix
    #   CustomFields::DateTimeField.name_prefix #=> dt
    def name_prefix
      'dt'
    end
    
    #Date.null_date
    def null_date
      Date.null_date
    end

    #   CustomFields::DateTimeField.cell_date(cell) -> date
    # Get date from cell value
    #   CustomFields::DateTimeField.cell_date(cell) #=> 18/08/2010
    #   CustomFields::DateTimeField.cell_date(nil) #=> Date.null_date
    def cell_date(cell_value)
      case cell_value
      when Cell
        cell_date(cell_value.value)
      else
        cell_value.to_date
      end
    end

    #   CustomFields::DateTimeField.check_date_in_range?(value, to, from) -> true/false
    # Check that date is in range ro not
    #   CustomFields::DateTimeField.check_date_in_range?(18/08/2010, 31/08/2010, 01/08/2010) #=> true
    #   CustomFields::DateTimeField.check_date_in_range?(nil, 31/08/2010, 01/08/2010) #=> false
    #   CustomFields::DateTimeField.check_date_in_range?(nil, Date.null_date, Date.null_date) #=> true
    def check_date_in_range?(value, to, from)
      dt_value = value.to_date
      dt_from = from.to_date
      dt_to = to.to_date

      if dt_from == null_date
        return true if dt_to == null_date
        return false if value.to_s == ''
        dt_value <= dt_to
      else
        if dt_to == null_date
          dt_from <= dt_value
        else
      dt_from <= dt_value && dt_value <= dt_to
    end
      end
    end
      
    #   CustomFields::DateTimeField.month(key) -> Fixnum
    # Get the month number for the specified month key
    #   # null_date = '2000/04/01'
    #   CustomFields::DateTimeField.month(:jan)   #=> 10
    #   CustomFields::DateTimeField.month(:fst_q) #=> 13
    #   CustomFields::DateTimeField.month(:snd_h) #=> 18
    #   CustomFields::DateTimeField.month(:year)  #=> 19
    def month(key)
      ([ nil] + months + [:fst_q, :snd_q, :thd_q, :for_q] + [:fst_h, :snd_h] + [:year]).index(key)
    end

    #   CustomFields::DateTimeField.month_description(index) -> string
    # Get month description
    #   CustomFields::DateTimeField.month_description(1) #=> "Jan"
    #   CustomFields::DateTimeField.month_description(2) #=> "Feb"
    def month_description(index)
      ([ nil] + months.collect{|m| m.to_s.capitalize} + ['1st Quater', '2nd Quater', '3rd Quater', '4th Quater'] + ['1st Half', '2nd Half'] + ['Year'])[index]
    end

    #   CustomFields::DateTimeField.tree_months -> hash
    # Get hash that contains month
    #   CustomFields::DateTimeField.tree_months #=> {:childs=> [{:childs=> [{:childs=>[{:descr=>:jan}, {:descr=>:feb}, {:descr=>:mar}], :descr=>:fst_q}, ...}
    def tree_months
      @@tree_months ||= {}
      if @@tree_months.empty?
        h_months = months.collect{|m| eval "{:descr => :#{m}}" }

        fst_q = {:descr => :fst_q, :childs => h_months[0..2] }
        snd_q = {:descr => :snd_q, :childs => h_months[3..5] }
        trd_q = {:descr => :thd_q, :childs => h_months[6..8] }
        fth_q = {:descr => :for_q, :childs => h_months[9..11] }

        fst_h = {:descr => :fst_h, :childs => [fst_q, snd_q]}
        snd_h = {:descr => :snd_h, :childs => [trd_q, fth_q]}

        @@tree_months = {:descr => :year, :childs => [fst_h, snd_h]}
      end

      @@tree_months
    end

    # CustomFields::DateTimeField.get_month_by_types(:long_month) = [1,2,3,4,5 .....]
    def get_month_by_types(type)
      result = []
      CustomFields::DateTimeField.get_month_by_type(CustomFields::DateTimeField.level(type), 0, result)
      
      result
    end

    # CustomFields::DateTimeField.get_months_path_by_date(dt_value) = [1, 13, 17, 19]
    def get_months_path_by_date(dt_value)
      #1. key = get_key(dt_value)
      #2. return array path [1, 13, 17, 19]
      case dt_value
      when String then dt_value = dt_value.to_date
      end
      
      dt_key = dt_value.strftime('%b').downcase.to_sym

      CustomFields::DateTimeField.get_month_path_by_date(dt_key).flatten
    end
    
    #CustomFields::DateTimeField.level
    def level(type)
      types = [nil, :year, :half_year, :quarter_year, :long_month]
      types.index(type.to_sym)
    end

    #CustomFields::DateTimeField.get_month_by_type
    def get_month_by_type(level, lo_level, result, tr_months = nil)
      tr_months ||= CustomFields::DateTimeField.tree_months
      unless tr_months[:childs].nil?
        lo_level += 1
        tr_months[:childs].each do |t|
          CustomFields::DateTimeField.get_month_by_type(level, lo_level, result, t) if lo_level < level
        end
        result << CustomFields::DateTimeField.month(tr_months[:descr]) if lo_level <= level
      else
        result << CustomFields::DateTimeField.month(tr_months[:descr])
      end
    end

    #CustomFields::DateTimeField.get_month_by_type
    def get_month_path_by_date(dt_key, tr_month = nil)
      tr_month ||= CustomFields::DateTimeField.tree_months
      if tr_month[:childs].nil? 
        CustomFields::DateTimeField.month(tr_month[:descr]) if tr_month[:descr] == dt_key 
      else
        result = tr_month[:childs].collect do |t|
          CustomFields::DateTimeField.get_month_path_by_date(dt_key, t)
        end.compact
        [CustomFields::DateTimeField.month(tr_month[:descr])] + result unless result.empty?
      end
    end

    #   CustomFields::DateTimeField.month_year(date_value) -> integer
    # Get number of month by date
    #   CustomFields::DateTimeField.month_year(01/08/2010) #=> 8
    def month_year(date_value)
      get_month_no(date_value, :long_month)
    end

    #   CustomFields::DateTimeField.quarter_year(date_value) -> integer
    # Get number of quarter year by date
    #   CustomFields::DateTimeField.quarter_year(01/08/2010) #=> 3
    def quarter_year(date_value)
      get_month_no(date_value, :quarter_year)
    end

    #   CustomFields::DateTimeField.half_year(date_value) -> integer
    # Get number of half year by date
    #   CustomFields::DateTimeField.half_year(01/08/2010) #=> 2
     def half_year(date_value)
      get_month_no(date_value, :half_year)
    end

    #   CustomFields::DateTimeField.begin_of_period(date_value, period) -> datetime
    # Get begining of period, a return value is datetime
    #   CustomFields::DateTimeField.begin_of_period(18/08/2011, :day) -> Mon Aug 18 00:00:00 +0700 2011
    #   CustomFields::DateTimeField.begin_of_period(18/08/2011, :month) -> Mon Aug 01 00:00:00 +0700 2011
    #   CustomFields::DateTimeField.begin_of_period(18/08/2011, :quarter_year) -> Fri Jul 01 00:00:00 +0700 2011
    #   CustomFields::DateTimeField.begin_of_period(18/08/2011, :half_year) -> Fri Jul 01 00:00:00 +0700 2011
    #   CustomFields::DateTimeField.begin_of_period(18/08/2011, :year) -> Sat Jan 01 00:00:00 +0700 2011
     def begin_of_period(date_value, period)
       dt = case period
       when :day
         date_value
       else
         case period
         when :month, :long_month
           count_month = 1
         when :quarter_year
           count_month = 3
         when :half_year
           count_month = 6
         when :year
           count_month = 12
         end
         
         dt = date_value.to_date >> - ((CustomFields::DateTimeField.month_year(date_value) -
               CustomFields::DateTimeField.month_year(Date.null_date)) % count_month)
         dt.beginning_of_month
       end
       
       dt.beginning_of_day
     end

     #   CustomFields::DateTimeField.end_of_period(date_value, period) -> datetime
     # Get end of period, a return value is datetime
     #   CustomFields::DateTimeField.end_of_period(18/08/2011, :day) -> Thu Aug 18 23:59:59 +0700 2011
     #   CustomFields::DateTimeField.end_of_period(18/08/2011, :month) -> Thu Aug 31 23:59:59 +0700 2011
     #   CustomFields::DateTimeField.end_of_period(18/08/2011, :quarter_year) -> Fri Sep 30 23:59:59 +0700 2011
     #   CustomFields::DateTimeField.end_of_period(18/08/2011, :half_year) -> Sat Dec 31 23:59:59 +0700 2011
     #   CustomFields::DateTimeField.end_of_period(18/08/2011, :half_year) -> Sat Dec 31 23:59:59 +0700 2011
     def end_of_period(date_value, period)
       dt = case period
       when :day
         date_value
       else
         case period
         when :month, :long_month
           count_month = 1
         when :quarter_year
           count_month = 3
         when :half_year
           count_month = 6
         when :year
           count_month = 12
         end

         (begin_of_period(date_value, period).to_s.to_date >> count_month) - 1
       end

       dt.end_of_day
     end

    private
    
    def months
      @month_keys ||= (1..12).to_a.collect do |m|
        month_date = (Date.null_date >> (m - 1))

        month_date.strftime('%b').downcase.to_sym
      end

      @month_keys
    end

    def get_month_no(date_value, type)
      case date_value
      when String
        get_month_no(date_value.to_date, type)
      when NilClass
        0
      else
        case type
        when :year
          date_value.year
        else
          case type
          when :long_month
            base = months.first
          when :quarter_year
            base = :fst_q
          when :half_year
            base = :fst_h
          end
          
          CustomFields::DateTimeField.get_months_path_by_date(date_value)[level(type) - 1] -
            CustomFields::DateTimeField.month(base)+1
        end
      end
    end

  end # class << self

  def search_value?(value, filter)
    return true if filter.nil?

    value = value.to_s.to_date
    null_date = Date.null_date

    if filter['status'] == 'not_set'
      return value == null_date
    else
      return false if value.to_s.empty?

      filter_from = (filter['from'].to_s.empty?) ?  null_date : filter['from'].to_date
      filter_to = (filter['to'].to_s.empty?) ? null_date : filter['to'].to_date

      if filter_from == null_date
        return true if filter_to == null_date
        return value <= filter_to && value != null_date
      else
        return false if value < filter_from
        return true if filter_to == null_date
        return value <= filter_to
      end

    end
  end

  def validate_filters(search_filter, require_search)
    null_date = Date.null_date
    filter_form = (search_filter['from'].to_s.empty?) ? null_date : search_filter['from'].to_date
    filter_to = (search_filter['to'].to_s.empty?) ? null_date : search_filter['to'].to_date
    required_filter = (require_search && 
      (filter_form == null_date && filter_to == null_date) && 
      search_filter['status'].to_s == 'set')
    invalid_filter = (filter_form <= filter_to) ? false : (filter_to != null_date)
    return {:required => required_filter, :invalid => invalid_filter}
  end

  def description
    'A custom field that stores dates with a time component'
  end

  #   custom_field.absolute_value(cell_value)  -> date
  # Get date value
  #   custom_field.absolute_value('01-01-2011') #=> #<Date: 4911125/2,0,2299161>
  def absolute_value(cell_value)
    value = cell_value.to_s
    value.empty? ? Date.null_date : value.to_date
  end

  #   custom_field.format_date -> symbol
  # Get format date
  #   custom_field.format_date -> :short_date
  def format_date
    self[:value]  ||= {}
    self[:value][:format_date] ||= :short_date
    self[:value][:format_date].to_sym
  end

  def format_time
    self[:value]  ||= {}
    self[:value][:format_time] ||= :none
    self[:value][:format_time].to_sym
  end

  #   custom_field.text(cell_value) -> string
  # Get string to display in screen
  #   cell.value #=> "2011-08-18"
  #   custom_field.text(cell.value) #=> "18/08/2011"
  def text(cell_value)
    return '' if cell_value.to_s.to_date == Date.null_date

    dt_value = cell_value.to_date
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

          period = CustomFields::DateTimeField.quarter_year(dt_value)
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
  
  def parse(value, options={})
    value.to_date
  end

  #   custom_field.default_value -> string
  # Get defaul value that have been set in custom field
  #   custom_field.default_value #=> "current_date"
  def default_value
    self[:value] ||= {}
    self[:value][:default_value] ||= 'empty'
    self[:value][:default_value]
  end

  #   custom_field.evaluate_default_value -> Time
  # Get evaluate default value
  #   custom_field.defalut => "currnet_date"
  #   custom_field.evaluate_default_value #=> Time.now
  def evaluate_default_value(options = {})
    if default_value == 'current_date' then
      Time.now
    else
      nil
    end
  end
end
