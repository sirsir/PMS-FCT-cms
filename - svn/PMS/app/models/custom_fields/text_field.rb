class CustomFields::TextField < CustomField

  DEFAULT_MAX_LENGTH = 50

  class << self

    #   CustomFields::TextField.name_prefix -> string
    #
    # Get the default name prefix
    #   CustomFields::TextField.name_prefix #=> txt
    def name_prefix
      'txt'
    end
  end

  def search_value?(value, filter)
    return true if filter.nil?

    !(value.to_s.strip =~ /#{Regexp.escape(filter.to_s.strip)}/i).nil?
  end
  
  def description
    'A basic single line text box custom field to allow simple text input.'
  end

  #   custom_field.default_value -> string
  # Get default value
  #   custom_field.default_value #=> ""
  def default_value
    self[:value] ||= {}
    self[:value][:default_value] ||= ''
  end

  #   custom_field.alphabet -> string
  # Get alphabet
  #   custom_field.alphabet #=> "all"
  def alphabet
    self[:value] ||= {}
    self[:value][:alphabet] ||= ''
  end

  #   custom_field.numeric -> string
  # Check that text area is include numeric or not
  #   custom_field.numeric #=> "true"
  def numeric
    self[:value] ||= {}
    self[:value][:numeric] ||= CustomFields::CheckBox.true_or_false?(self[:value][:numeric])
  end

  #   custom_field.non_english -> string
  # Check that text area is include non_english or not
  #   custom_field.non_english #=> "true"
  def non_english
    self[:value] ||= {}
    self[:value][:non_english] ||= CustomFields::CheckBox.true_or_false?(self[:value][:non_english])
  end

  #   custom_field.symbols -> array
  # Get symbols thata has been set in custom field
  #   custom_field.symbols #=> ["-1"]
  def symbols
    self[:value] ||= {}
    self[:value][:symbols] ||= []
  end

  #   custom_field.min_length -> string
  # Get minimum length
  #   custom_field.min_length #=> "0"
  def min_length
    self[:value] ||= {}
    self[:value][:min_length] ||= 0
  end

  #   custom_field.max_length -> string
  # Get maximum length
  #   custom_field.max_length #=> "300"
  def max_length
    self[:value] ||= {}
    self[:value][:max_length] ||= DEFAULT_MAX_LENGTH
  end

  #   custom_field.option -> hash
  # Get option
  #   custom_field.option #=> {:numeric=>"true",  :symbols=>[],  :alphabet=>"all",  :length=>{:max=>"50", :min=>"0"}}
  def option
    @option ||= {
      :length => { :min => self.min_length, :max => self.max_length },
      :alphabet => self.alphabet,
      :numeric => self.numeric,
      :symbols => self.symbols.collect{|s| CustomFields::NoneAlphaNumeric.find(s) }.compact,
      :non_english => self.non_english
    }
  end

  def parse(value, options={})
    value
  end

  #   custom_field.validate_value(cell_value, options) -> string
  #
  #   options = {
  #    :throw_exception => false
  #   }
  # Get cell value
  #   custom_field.validate_value("100") #=> 100
  #   custom_field.validate_value("100.50") #=> 100.50
  #   custom_field.validate_value("@TseStaff") #=> @TseStaff
  #
  #   options = {
  #    :throw_exception => true, :alphabet => upper_case, :numeric=>"true",
  #    :symbols=>[], :length=>{:max=>"50", :min=>"0"}
  #   }
  # Get cell value and check format, display error message if wrong format
  #   custom_field.validate_value("TSE1") #=> TSE1
  #   custom_field.validate_value("TSE@1") #=> error message: "can't use symbols"
  #   custom_field.validate_value("") #=> ""
  def validate_value(cell_value, options = {})
    defaults = {
      :throw_exception => false
    }
    options = defaults.merge(options)

    case cell_value
    when Cell
      validate_value(cell_value.value)
    when String
      # Check format
      if options[:throw_exception]
        raise "is too long (maximum is #{self.option[:length][:max].to_s} characters)" if cell_value.size > self.option[:length][:max].to_i
        raise "is too Short (minimum is #{self.option[:length][:min].to_s} characters)" if cell_value.size < self.option[:length][:min].to_i

        raise "can't use numeric" if (self.option[:numeric].to_s == 'false') && (cell_value =~ /[0-9]/)
        if self.option[:alphabet].to_s.empty?
          raise "can't use alphabet" if cell_value =~ /[a-zA-Z_]/
        else
          if self.option[:alphabet].to_s == 'upper_case'
            raise "can't use lowercase" if cell_value =~ /[a-z]/
          else
            raise "can't use uppercase" if (self.option[:alphabet].to_s == 'lower_case') && (cell_value =~ /[A-Z]/)
          end
        end

        if self.option[:symbols].to_s.empty?
          str_stranger = cell_value
          str_stranger = str_stranger.gsub(/[ก-๛⸗-鿋]/u, '')

          raise "can't use symbols" if (!(str_stranger =~ /[^0-9a-zA-Z_ ]/).nil? and !str_stranger.empty?)

          #CHECK if it contain other char
          str_stranger = cell_value
          str_stranger = str_stranger.gsub(/[ก-๛⸗-鿋]/u, '') if self.option[:non_english].to_s == 'true'
          str_stranger = str_stranger.gsub(/[0-9a-zA-Z_ ]/, '')

          unless str_stranger.empty?
            raise_message = "can use only English"
            raise_message << ", Thai and Japanese" if self.option[:non_english].to_s == 'true'
            raise_message << " characters."

            raise raise_message
          end
        else
          symb = self.option[:symbols].collect { |c| c.symbol }

          str_stranger = cell_value
          str_stranger = str_stranger.gsub(/[#{Regexp.escape(symb.to_s)}]/, '')
          str_stranger = str_stranger.gsub(/[0-9a-zA-Z_ ]/, '')
          str_stranger = str_stranger.gsub(/[ก-๛⸗-鿋]/u, '') if self.option[:non_english].to_s == 'true'
          
          unless str_stranger.empty?
            raise_message = "can use only symbols: #{symb.collect{|i| i = i+' ' }.to_s}"
            raise_message << ", Thai, Japanese" if self.option[:non_english].to_s == 'true'
            raise_message << " and English characters"

            raise raise_message
          end
        end
      end

      cell_value
    else
      validate_value(cell_value.to_s)
    end
  end

end
