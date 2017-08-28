module CustomFields

  class Calendar < CustomField

    class << self

      #   CustomFields::Calendar.cell_date(cell_value) -> date
      # Get selected_date.
      #   CustomFields::Calendar.cell_date(cell_value) #=> Fri, 01 Jan 2010
      #   CustomFields::Calendar.cell_date({}) #=> Date.null_date
      #   CustomFields::Calendar.cell_date(nil) #=> Date.null_date
      def cell_date(cell_value)
        case cell_value
        when Cell
          cell_date(cell_value.value)
        when String
          cell_date(nil)
        else
          cell_value ||= {}

          cell_value[:selected_date].to_date
        end
      end

      #   CustomFields::Calendar.cell_date_from(cell_value) -> date
      # Get start date of calendar.
      # notes a value come from selected date.
      #   CustomFields::Calendar.cell_date_from(cell_value) #=> Fri, 01 Jan 2010
      #   CustomFields::Calendar.cell_date_from({}) #=> Date.null_date
      #   CustomFields::Calendar.cell_date_from(nil) #=> Date.null_date
      def cell_date_from(cell_value)
        cell_date(cell_value)
      end

      #   CustomFields::Calendar.cell_date_to(cell_value, custom_field) -> datetime
      # Get end date of calendar.
      #   CustomFields::Calendar.cell_date_from(cell_value) #=> Fri, 01 Jan 2010
      #   CustomFields::Calendar.cell_date_to(cell_value, custom_field) #=> Sun Dec 31 23:59:59 +0700 2000
      #   CustomFields::Calendar.cell_date_to({}, custom_field) #=> Sun Dec 31 23:59:59 +0700 2000
      #   CustomFields::Calendar.cell_date_to(nil, custom_field) #=> Sun Dec 31 23:59:59 +0700 2000
      def cell_date_to(cell_value, custom_field)
        # ToDo: use custom_field to get date range
        ((cell_date_from(cell_value) >> 12) - 1).end_of_day
      end


      def calendar_value_row(cell, date_time)
        if cell.calendar_values.empty?
          # ToDo: Get period from CustomField's format
          cell.calendar_values = CustomFields::Calendar.create_detail_rows(cell.id, CustomFields::DateTimeField.begin_of_period(date_time, :year), cell.field.detail_screen_id)
        end
        
        first_cv = cell.calendar_values.first
        last_cv = cell.calendar_values.last
        
        from_date_time = first_cv.date_time

        to_date_time = case
        when cell.field.monthly_format?
          last_cv.date_time.end_of_month
        else
          raise 'Unimplemented switch case'
        end

        dt = date_time.to_time

        if from_date_time <= dt && dt <= to_date_time
          calendar_value = cell.calendar_values.inject{|selected_cv, cv|
            selected_cv = (selected_cv.date_time < cv.date_time && cv.date_time <= dt) ? cv : selected_cv
          }

          calendar_value.row
        end
      end

      #   CustomFields::Calendar.create_detail_rows(cell_id, date, detail_screen_id) -> array
      # create derail rows for each month.
      # a result is array that contain detail rows.
      def create_detail_rows(cell_id, date, detail_screen_id)
        calendar_values = []
        
        ActiveRecord::Base.transaction do
          start_date = date.to_time
          end_date = CustomFields::DateTimeField.end_of_period(start_date, :year)
          while(start_date < end_date)
            detail_row = DetailRow.new(:screen_id => detail_screen_id, :remark => '')
            Row.save(detail_row, [], :log_action => :created)

            calendar_value = Cells::CalendarValue.new(:row_id => detail_row.id, :date_time => start_date, :cell_id => cell_id)
            calendar_value.row = detail_row
            calendar_value.save
            
            calendar_values << calendar_value

            # ToDo: use custom_field to get datetime shift
            start_date = (start_date.to_date >> 1).beginning_of_day
          end
        end

        calendar_values
      end
    end

    def format_type
      [:monthly, :weekly, :daily, :shift, :hourly]
    end

    def description
      'Calendar'
    end

    #   calendar.is_calendar_format? -> true/false
    # Check that a calendar is expected format or not
    #   calendar.is_calendar_format?('monthly') #=> true
    #   calendar.is_calendar_format?('weekly') #=> false
    #   calendar.is_calendar_format?(nil) #=> false
    def is_calendar_format?(calendar_format)
      calendar_format.to_s.empty? ? false : !(self.format.to_s =~ /#{calendar_format}/).nil?
    end

    #   calendar.monthly_format? -> true/false
    # Check that a calendar is monthly format or not
    #   calendar.monthly_format? #=> true
    def monthly_format?
      is_calendar_format?(:monthly)
    end

    #   calendar.format -> calendar_format with type symbol
    # Get calendar format
    #   calendar.format #=> :monthly
    def format
      self[:value] ||= {}
      self[:value][:format] ||= ''
      
      self[:value][:format].to_sym
    end

    #   calendar.strat_of_week -> string
    # Get start of week if calendar is weekly format
    #   calendar.start_of_week #=> ''
    def start_of_week
      self[:value] ||= {}
      self[:value][:start_of_week] ||= ''
    end

    #   calendar.detail_screen_id -> integer
    # Get detail screen id that has been set for calendar
    #   calendar.detail_screen_id #=> 196
    def detail_screen_id
      self[:value] ||= {}
      self[:value][:detail_screen] ||= ''

      self[:value][:detail_screen].to_i
    end

    #   calendar.detail_screen -> detail_screen_object
    # Get detail screen's object that has been set for calendar
    #   calendar.detail_screen #=> #DetailScreen
    def detail_screen
      Screen.find(detail_screen_id)
    end

    def get_start_time
      self[:value] ||= {}      
      self[:value][:time].nil? ? Time.now : Time.mktime(Time.now.year, Time.now.month,
        Time.now.day, self[:value][:time][:start][:hour], self[:value][:time][:start][:minute])
    end

    def get_end_time
      self[:value] ||= {}
      self[:value][:time].nil? ? Time.now : Time.mktime(Time.now.year, Time.now.month,
        Time.now.day, self[:value][:time][:end][:hour], self[:value][:time][:end][:minute])
    end

    #   calendar.get_row_id(key) -> string
    # Get detail row id
    #   calendar.get_row_id('calendar_value_row_123') #=> '123'
    def get_row_id(key)
      key.delete '^[0-9]'
    end
    
    def html(cell)
      value = []

      case self.format
      when :monthly
        selected_date = cell.value[:selected_date].to_date

        start_date = CustomFields::DateTimeField.begin_of_period(selected_date, :year)
        end_date = CustomFields::DateTimeField.end_of_period(selected_date, :year)

        diff_year =  start_date.year != end_date.year

        if selected_date == Date.null_date
          value = ['']*13
          value << '' if diff_year
        else
          value << start_date.year

          detail_fields = cell.field.detail_screen.fields.select{|field| field.display_in_list? }
          display_label = detail_fields.length > 1

          cell.calendar_values.each do |calendar_value|
            value << start_date.year.to_s if (start_date == end_date.beginning_of_year) && diff_year

            value << detail_fields.collect do |detail_field|
              content_value = case detail_field
              when Fields::Data
                actual_row = Field.row_by_field(detail_field, calendar_value.row)
                cv_cell = actual_row.cell(detail_field.custom_field_id) unless actual_row.nil?

                cv_cell.to_html unless cv_cell.nil? || cv_cell.value.to_s == ''
              else
                detail_field.evaluate_value(calendar_value.row)
              end

              "#{detail_field.label_descr + ' : ' if display_label}#{content_value}<br>" unless content_value.nil?
            end.compact.join

            start_date = start_date.next_month
          end
        end
      end

      value
    end

    def parse(value, options={})
      #~ ToDo: The data for the sub detail screen is required
      super
    end

    def search_value?(value, filter)
      filter_date = filter[:selected_date].to_date
      
      if filter_date == Date.null_date
        return true
      else
        value_date = value[:selected_date].to_date

        # ToDo: Add conditions for other date formats
        return filter_date.year == value_date.year
      end
    end

    #   calendar.text(value) -> string
    # Get text to display in screen
    #   Date.null_date #=> 2000-01-01
    #   calendar.text({:selected_date => '2010-01-01'}) #=> 'Selected date 2010'
    #   calendar.text({}) #=> 'Selected date 2000'
    def text(value)
      year = value[:year] ||= value[:selected_date].to_date.year.to_s
      "Selected date #{year}"
    end

  end # end class Calendar

end # end module CustomFields