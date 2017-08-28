class CustomFields::NumericFormat
  attr_accessor :name
  attr_accessor :descr
  attr_accessor :option

  class << self

    #   CustomFields::NumericFormat.format_collection -> array
    # Get array that contain custom field, each custom field was create from list format
    #   CustomFields::NumericFormat.format_collection #=> [#CustomField, #CustomField, ...]
    def format_collection
      numeric_formats.collect{|k, v| v }.sort{|a, b| a.descr <=> b.descr}
    end

    #   CustomFields::NumericFormat.option_collection -> array
    # Get array that contains options
    #   CustomFields::NumericFormat.option_collection #=> [:precision, :separator, :delimiter, :unit, :rounding, :significance, :prefix_multiplier]
    def option_collection
      list_option
    end

    #   CustomFields::NumericFormat.currency_unit_collection -> array
    # Get array that contains currency units
    #   CustomFields::NumericFormat.currency_unit_collection #=> [{:name=>"USD", :descr=>"($)USD - US Dollar", :symbol=>"($)"}, ...]
    def currency_unit_collection
      list_currency_unit.collect{|k,v| v}.sort{|a, b| a[:descr] <=> b[:descr]}
    end

    #   CustomFields::NumericFormat.rounding_collection -> array
    # Get array that contains rounding options
    #   CustomFields::NumericFormat.rounding_collection #=> [{:name=>"ceil", :descr=>"ceil"}, {:name=>"round", :descr=>"round"}, {:name=>"None", :descr=>"None"}, {:name=>"floor", :descr=>"floor"}]
    def rounding_collection
      list_rounding.collect{|k,v| v}
    end

    #   CustomFields::NumericFormat.prefix_multiplier_collection -> array
    # Get array that contains prefix multipliers
    #   CustomFields::NumericFormat.prefix_multiplier_collection -> [{:descr=>"K", :name=>"K"},  {:descr=>"M", :name=>"M"},  {:descr=>"None", :name=>"None"}]
    def prefix_multiplier_collection
      list_prefix_multiplier.collect{|k,v| v}
    end

    #   CustomFields::NumericFormat.find(format_name) -> custom_field_object
    # Get custom field object by finding from format name
    #   CustomFields::NumericFormat.find(:number) #=> #CustomField
    #   CustomFields::NumericFormat.find('') #=> nil
    #   CustomFields::NumericFormat.find(nil) #=> nil
    def find(format_name)
      numeric_formats[format_name]
    end

    #   CustomFields::NumericFormat.find_currency_unit(unit_name) -> hash
    # Get currency unit by finding from unit name
    #   CustomFields::NumericFormat.find_currency_unit(:USD) #=> {:descr=>"($)USD - US Dollar", :name=>"USD", :symbol=>"($)"}
    #   CustomFields::NumericFormat.find_currency_unit('') #=> nil
    #   CustomFields::NumericFormat.find_currency_unit(nil) #=> nil
    def find_currency_unit(unit_name)
      list_currency_unit[unit_name]
    end

    private

    def numeric_formats
      @@cached_numeric_formats ||= {}

      list_format.each do |k, v|
        cf = CustomFields::NumericFormat.new
        cf.name = k
        cf.descr = k.to_s.sub('_', ' ').capitalize
        cf.option = v

        @@cached_numeric_formats[k] = cf
      end if @@cached_numeric_formats.empty?

      @@cached_numeric_formats
    end

    def list_format
      {
        :number => [:precision, :separator, :delimiter, :rounding, :significance, :prefix_multiplier],
        :percentage => [:precision, :separator, :delimiter, :rounding, :significance, :prefix_multiplier],
        :currency => [:precision, :separator, :delimiter, :unit, :rounding, :significance, :prefix_multiplier],
        :human_size => [:precision, :separator, :delimiter, :rounding, :significance, :prefix_multiplier]
      }
    end

    def list_option
      [:precision, :separator, :delimiter, :unit, :rounding, :significance, :prefix_multiplier]
    end

    def list_rounding
      {
        :None   => {:descr => 'None', :name => 'None'},
        :ceil   => {:descr => 'ceil', :name => 'ceil'},
        :floor  => {:descr => 'floor', :name => 'floor'},
        :round  => {:descr => 'round', :name => 'round'}
      }
    end

    def list_prefix_multiplier
      {
        :None => {:descr => 'None', :name => 'None'},
        :K    => {:descr => 'K', :name => 'K'},
        :M    => {:descr => 'M', :name => 'M'},
      }
    end

    def list_currency_unit
      {
        :USD => {:descr => '($)USD - US Dollar', :name => 'USD', :symbol => '($)'},
        :EUR => {:descr => '(€)EUR - Euro', :name => 'EUR', :symbol => '(€)'},
        :GBP => {:descr => '(£)GBP - British Pound', :name => 'GBP', :symbol => '(£)'},
        :JPY => {:descr => '(¥)JPY - Japanese Yen', :name => 'JPY', :symbol => '(¥)'},
        :THB => {:descr => '(฿)THB - Thai Baht', :name => 'THB', :symbol => '(฿)'}
      }
    end

  end
end