#  def value
#    {
#      :format => :phone, # :number, :currency / :human_size / :percentage / :phone
#      :options => {
#        :precision => 2,
#        :unit => "&yen;", # &nbsp; / &pound; / &yen; / $ / THB
#        :separator => ".",
#        :delimiter => ",",
#        :format => nil,
#        :area_code => false,
#        :extension => nil,
#        :country_code => nil
#      }
#    }
#  end

class CustomFields::NumericField < CustomField

  class << self
    include ActionView::Helpers::NumberHelper

    #   CustomFields::NumericField.name_prefix -> string
    #
    # Get the default name prefix
    #   CustomFields::NumericField.name_prefix #=> num
    def name_prefix
      'num'
    end

    #   CustomFields::NumericField.cleanse_all -> array
    def cleanse_all
      numeric_customer_fields = CustomFields::NumericField.find(:all)
      numeric_customer_fields.collect do |cf|
        cleanse(cf)
      end
    end

    #   CustomFields::NumericField.cleanse(customer_field) -> array
    def cleanse(customer_field)
      invalid_cells = customer_field.cells.select{|c| c.value.to_s =~ /[^0-9\-.]/}
      invalid_cells.each do |c|
        c.value = validate_value(c.value, customer_field.option[:separator])

        c.save
      end
    end  

    #   CustomFields::NumericField.validate_value(cell_value, separator = '.') -> float
    # Get cell value, notes if last n digit is zero it will be remove
    #   CustomFields::NumericField.validate_value('100.00') #=> 100
    #   CustomFields::NumericField.validate_value('100.50') #=> 100.5
    #   CustomFields::NumericField.validate_value('') #=> nil
    #   CustomFields::NumericField.validate_value(nil) #=> nil
    def validate_value(cell_value, separator = '.')
      case cell_value
      when Cell
        validate_value(cell_value.value, separator)
      when String
        cell_value.gsub!(separator, '.') unless separator.to_a.empty?
        cell_value.gsub(/[^0-9\-.]/, '').to_f unless cell_value.empty?
      else
        cell_value
      end
    end
    
    #   CustomFields::NumericField.validate_custom_field_value(hash, hash = nil) -> nil
    # Initialize the custom field's value by adding the missing keys
    # 
    # Defaults
    #   :delimiter = ','
    #   :separator = '.'
    #   :precision = 2
    #   :unit = :USD
    #   :rounding = :None
    #   :significance = 1.0
    #   :prefix_multiplier = :None
    #
    #   custom_field_value = {}
    #   CustomFields::NumericField.validate_custom_field_value(custom_field_value)
    #   custom_field_value  #=> {
    #                       #     :option => {
    #                       #         :separator => ".",
    #                       #         :precision => 2,
    #                       #         :rounding => :None,
    #                       #         :delimiter => ",",
    #                       #         :significance => 1.0,
    #                       #         :unit => :USD,
    #                       #         :prefix_multiplier => :None
    #                       #       }
    #                       #     }
    #
    #   custom_field_value = {
    #     :option => {
    #       :separator=>' ',
    #       :precision=>'4',
    #       :significance=>'1000.0'
    #     }
    #   }
    #   CustomFields::NumericField.validate_custom_field_value(custom_field_value)
    #   custom_field_value  #=> {
    #                       #     :option => {
    #                       #       :separator => " ",
    #                       #       :precision => 4,
    #                       #       :rounding => :None,
    #                       #       :delimiter => ",",
    #                       #       :significance => 1000.0,
    #                       #       :unit => :USD,
    #                       #       :prefix_multiplier => :None
    #                       #     }
    #                       #   }
    #
    def validate_custom_field_value(custom_field_value, default_options = nil)
      if custom_field_value.is_a?(Hash)
        default_options ||= {
          :delimiter => ',',
          :separator => '.',
          :precision => 2,
          :unit => :USD,
          :rounding => :None,
          :significance => 1.0,
          :prefix_multiplier => :None
        }
        
        custom_field_value[:option] ||= {}
        custom_field_value[:option].delete_if{|k,v| v.to_s.empty? }

        default_options.keys.each {|k| custom_field_value[:option][k] = default_options[k] if custom_field_value[:option][k].nil?}
       
        custom_field_value[:option].each_key do |k|
          custom_field_value[:option][k] = case k.to_sym
          when :precision
            custom_field_value[:option][k].to_i
          when :unit
            custom_field_value[:option][k].to_sym
          when :significance
            custom_field_value[:option][k].to_f
          else
            custom_field_value[:option][k]
          end
        end
      end
    end

    #   CustomFields::NumericField.ceil(value, decimal) -> decimal
    # Get the smallest decimal number greater than or equal to value.
    #   CustomFields::NumericField.ceil(10.1, 1) #=> 10.1
    #   CustomFields::NumericField.ceil(10.9, 1) #=> 10.9
    #   CustomFields::NumericField.ceil(10.01, 1) #=> 10.1
    #   CustomFields::NumericField.ceil(10.09, 1) #=> 10.1
    #   CustomFields::NumericField.ceil(10.1, 2) #=> 10.10
    #   CustomFields::NumericField.ceil(10.9, 2) #=> 10.90
    #   CustomFields::NumericField.ceil(10.01, 2) #=> 10.01
    #   CustomFields::NumericField.ceil(10.09, 2) #=> 10.09
    def ceil(value, decimal)
      round_to_significance(value, decimal_to_significance(decimal), :ceil)
    end

    #   CustomFields::NumericField.ceil_to(value, decimal) -> decimal
    # Get the smallest decimal number greater than or equal to value.
    #   CustomFields::NumericField.ceil_to(10.1, 0.1) #=> 10.1
    #   CustomFields::NumericField.ceil_to(10.9, 0.1) #=> 10.9
    #   CustomFields::NumericField.ceil_to(10.01, 0.1) #=> 10.1
    #   CustomFields::NumericField.ceil_to(10.09, 0.1) #=> 10.1
    #   CustomFields::NumericField.ceil_to(10.1, 0.01) #=> 10.10
    #   CustomFields::NumericField.ceil_to(10.9, 0.01) #=> 10.90
    #   CustomFields::NumericField.ceil_to(10.01, 0.01) #=> 10.01
    #   CustomFields::NumericField.ceil_to(10.09, 0.01) #=> 10.09
    def ceil_to(value, significance)
      round_to_significance(value, significance, :ceil)
    end

    #   CustomFields::NumericField.floor(value, decimal) -> decimal
    # Get the largest decimal number less than or equal to value.
    #   CustomFields::NumericField.floor(10.1, 1) #=> 10.1
    #   CustomFields::NumericField.floor(10.9, 1) #=> 10.9
    #   CustomFields::NumericField.floor(10.01, 1) #=> 10.0
    #   CustomFields::NumericField.floor(10.09, 1) #=> 10.0
    #   CustomFields::NumericField.floor(10.1, 2) #=> 10.1
    #   CustomFields::NumericField.floor(10.9, 2) #=> 10.9
    #   CustomFields::NumericField.floor(10.01, 2) #=> 10.01
    #   CustomFields::NumericField.floor(10.09, 2) #=> 10.09
    def floor(value, decimal)
      round_to_significance(value, decimal_to_significance(decimal), :floor)
    end

    #   CustomFields::NumericField.floor_to(value, decimal) -> decimal
    # Get the largest decimal number less than or equal to value.
    #   CustomFields::NumericField.floor_to(10.1, 0.1) #=> 10.1
    #   CustomFields::NumericField.floor_to(10.9, 0.1) #=> 10.9
    #   CustomFields::NumericField.floor_to(10.01, 0.1) #=> 10.0
    #   CustomFields::NumericField.floor_to(10.09, 0.1) #=> 10.0
    #   CustomFields::NumericField.floor_to(10.1, 0.01) #=> 10.1
    #   CustomFields::NumericField.floor_to(10.9, 0.01) #=> 10.9
    #   CustomFields::NumericField.floor_to(10.01, 0.01) #=> 10.01
    #   CustomFields::NumericField.floor_to(10.09, 0.01) #=> 10.09
    def floor_to(value, significance)
      round_to_significance(value, significance, :floor)
    end

    #   CustomFields::NumericField.round(value, decimal) -> decimal
    # Get decimal than nearest value.
    #   CustomFields::NumericField.round(10.1, 1) #=> 10.1
    #   CustomFields::NumericField.round(10.9, 1) #=> 10.9
    #   CustomFields::NumericField.round(10.01, 1) #=> 10.0
    #   CustomFields::NumericField.round(10.09, 1) #=> 10.1
    #   CustomFields::NumericField.round(10.1, 2) #=> 10.10
    #   CustomFields::NumericField.round(10.9, 2) #=> 10.90
    #   CustomFields::NumericField.round(10.01, 2) #=> 10.01
    #   CustomFields::NumericField.round(10.09, 2) #=> 10.09
    def round(value, decimal)
      round_to_significance(value, decimal_to_significance(decimal), :round)
    end

    #   CustomFields::NumericField.round_to(value, decimal) -> decimal
    # Get decimal than nearest value.
    #   CustomFields::NumericField.round_to(10.1, 0.1) #=> 10.1
    #   CustomFields::NumericField.round_to(10.9, 0.1) #=> 10.9
    #   CustomFields::NumericField.round_to(10.01, 0.1) #=> 10.0
    #   CustomFields::NumericField.round_to(10.09, 0.1) #=> 10.1
    #   CustomFields::NumericField.round_to(10.1, 0.01) #=> 10.10
    #   CustomFields::NumericField.round_to(10.9, 0.01) #=> 10.90
    #   CustomFields::NumericField.round_to(10.01, 0.01) #=> 10.01
    #   CustomFields::NumericField.round_to(10.09, 0.01) #=> 10.09
    def round_to(value, significance)
      round_to_significance(value, significance, :round)
    end

    #   CustomFields::NumericField.apply_format_option(value, format, option) -> value
    # Get value in expected format
    #   option => {"separator" => ., "delimiter" => ",", "precision" => "2"}
    #   format => :number
    #   CustomFields::NumericField.apply_format_option(10, format, option) #=> 10.00
    #   CustomFields::NumericField.apply_format_option(10.1, format, option) #=> "10.10"
    #   CustomFields::NumericField.apply_format_option(10.9, format, option) #=> "10.90"
    def apply_format_option(value, format, option)
      case value
      when Float
        cf_format = format
        cf_options = option
        
        value = send("#{cf_options[:rounding].to_s}_to", value, cf_options[:significance].to_f) if cf_options[:rounding].to_sym != :None

        if cf_format != :human_size && cf_options[:prefix_multiplier].to_sym != :None
          prefix_multiplier_value = 10**3
          prefix_multiplier_value = 10**6 if cf_options[:prefix_multiplier].to_sym == :M

          value = value / prefix_multiplier_value
        end

        case cf_format
        when :number, :currency then
          number_with_precision(value, cf_options)
        when :percentage then
          number_to_percentage(value, cf_options)
        when :human_size then
          number_to_human_size(value, cf_options)
        end
      else
        value
      end
    end

    private

    def round_to_significance(value, significance, type)
      value = (value/0.0000000001).round * 0.0000000001 unless type == :round
      
      significance = significance.to_f
      significance = 1.0 unless significance > 0.0
      
      (value/significance).send(type)*significance
    end
    
    def decimal_to_significance(decimal)
      (10**-(decimal.to_i)).to_f
    end
  end

  def cleanse
    CustomFields::NumericField.cleanse(self)
  end

  def search_value?(value, filter)
    return true if filter.nil?
    
    if (value.empty? and filter[:from].to_s.strip.empty? and filter[:to].to_s.strip.empty?)
      return true
    else
      max_value = 10**20 #~ 100,000,000,000,000,000,000
      filter[:from] = (-max_value).to_s if filter[:from].to_s.strip.empty?
      filter[:to] = max_value.to_s if filter[:to].to_s.strip.empty?
      value = '0.0' if value.to_s.strip.empty?
      
      value = value.to_s.gsub(/[^0-9.-]/,'').to_f
      filter[:from] = filter[:from].to_s.gsub(/[^0-9.-]/,'').to_f
      filter[:to] = filter[:to].to_s.gsub(/[^0-9.-]/,'').to_f
      
      filter.nil? or (filter[:from] <= value and value <= filter[:to])
    end
  end
  
  def description
    'Numeric Field'
  end

  #   custom_field.validate_value(cell_value, options = {}) -> decimal
  # Get validate value
  #   custom_field.validate_vallue('10') #=> 10.0
  #   custom_field.validate_vallue('10.0') #=> 10.0
  #   custom_field.validate_vallue('10.00') #=> 10
  #   custom_field.validate_vallue('10.000') #=> 10.00
  #   custom_field.validate_vallue('') #=> nil
  #   custom_field.validate_vallue(nil) #=> nil
  def validate_value(cell_value, options = {})
    CustomFields::NumericField.validate_value(cell_value, option[:separator])
  end

  #   custom_field.absolute_value(cell_value) -> decimal
  # Get absolute value
  #   custom_field.absolute_value('10') #=> 10.0
  #   custom_field.absolute_value('10.0') #=> 10.0
  #   custom_field.absolute_value('10.00') #=> 10
  #   custom_field.absolute_value('10.000') #=> 10.00
  #   custom_field.absolute_value('') #=> nil
  #   custom_field.absolute_value(nil) #=> nil
  def absolute_value(cell_value)
    validate_value(cell_value)
  end

  #   custom_field.default_value -> decimal
  # Get default value
  #   custom_field.default_value #=> 0.0
  def default_value
    self[:value] ||= {}
    self[:value][:default_value] ||= ''
    self[:value][:default_value].to_f unless self[:value][:default_value].empty?
  end

  #   need to implement
  def default_option
    CustomFields::NumericFormat.default_option(format)
  end   

  #   custm_field.format -> symbol
  # Get custom field format
  #   custom_field.format #=> :number
  def format
    if !self[:value].nil?
      formats = self[:value].delete(:format)
      options = self[:value].delete(:option)
      df_value = self[:value].delete(:default_value)

      self[:value] = {}
      self[:value][:format] = formats
      self[:value][:option] = {}
      if !options.nil?
        options.keys.each {|k| self[:value][:option][k.to_sym] = options[k] if self[:value][:option][k.to_sym].nil?}
      end
      self[:value][:default_value] = df_value
    end
    self[:value] ||= {}
    self[:value][:format] ||= :number
    self[:value][:format].to_sym
  end

  #   custom_field.options -> hash
  # Get custom field option
  #   custom_field.options #=> {:delimiter=>",", :separator=>".",:precision=>2, ...}
  def option
    self[:value] ||= {}
    
    CustomFields::NumericField.validate_custom_field_value(self[:value])
    
    self[:value][:option]
  end

  #   custom_field.label_descr -> string
  # Get label description
  #   custom_field.label_descr #=> "Numeric Field"
  def label_descr
    @label_descr ||= label.nil? ? Label.missing_msg(self[:label_id]) : display_label_descr
  end

  #   custom_field.display_label_descr -> string
  # Get label description
  #   custom_field.display_label_descr #=> "Numeric Field"
  def display_label_descr
    currency = " #{CustomFields::NumericFormat.find_currency_unit(option[:unit].to_sym)[:symbol]}" if format == :currency
    "#{label.descr}#{currency}"
  end

  #   custom_field.text(cell_value) -> string
  # Get string to display in screen
  #   custom_field.text(cell_value) #=> "50.0"
  def text(cell_value)
    apply_format(cell_value, format, option.merge(:delimiter => '')).to_s
  end

  #   custom_field.html(cell_value) -> string
  # Get string to display in screen
  #   custom_field.html(cell_value) #=> "50.0"
  def html(cell_value)
    apply_format(cell_value, format, option).to_s
  end

  def parse(value, options={})
    validate_value(value)
  end

  private
  
  def apply_format(cell_value, format, option)
    cell_value = absolute_value(cell_value)
    CustomFields::NumericField.apply_format_option(cell_value, format, option)
  end
end
