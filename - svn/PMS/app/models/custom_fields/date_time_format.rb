class CustomFields::DateTimeFormat
  attr_accessor :name
  attr_accessor :descr
  attr_accessor :format

  class << self

    #   CustomFields::DateTimeFormat.date_options_collection -> array
    # Get an array that contains option of date format ex. :shot_date, :long_date
    # each value is CustomField
    #   CustomFields::DateTimeFormat.date_options_collection #=> [#CustomField::DateTimeFormat, #CustomField::DateTimeFormat, ...]
    def date_options_collection
      date_formats.collect{|k, v| v }.sort{|a, b| a.descr <=> b.descr}
    end

    def find_by_name(name)
      date_formats[name]
    end

    def strf_date(format,date)
      date.strftime(find_by_name(format).format)
    end

    private

    def date_formats
      @@cached_date_formats ||= {}

      list_date_format.each do |k, v|
        cf = CustomFields::DateTimeFormat.new
        cf.name = k
        cf.descr = v[:descr]
        cf.format = v[:format]

        @@cached_date_formats[k] = cf
      end if @@cached_date_formats.empty?

      @@cached_date_formats
    end

    def list_date_format
      {
        :short_date => { :descr => 'Short Date (28/02/2009)', :format => '%d/%m/%Y' },
        :long_date => { :descr => 'Long Date (28 Febuary 2009)', :format => '%d %B %Y' },
        :short_month => { :descr => 'Short Month (02/2009)', :format => '%m/%Y' },
        :long_month => { :descr => 'Long Month (Febuary 2009)', :format => '%B %Y' },
        :quarter_year => { :descr => 'Quarter Year (1st Quarter,2009)', :format => '' },
        :half_year => { :descr => 'Half Year (1st Half,2009)', :format => '' },
        :year => { :descr => 'Year (2009)', :format => '%Y' }
      }
    end

    def list_time_format
      {
        :none => { :descr => '', :format => '' },
        :hour => { :descr => '', :format => '' },
        :minute => { :descr => '', :format => '' },
        :second => { :descr => '', :format => '' }
      }
    end

  end
end