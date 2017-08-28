class CustomFields::NoneAlphaNumeric
  attr_accessor :symbol
  attr_accessor :descr

  class << self

    #   CustomFields::NoneAlphaNumeric.collection -> array
    # Get symbols, a return value is array that contain #CustomField
    #   CustomFields::NoneAlphaNumeric.collection #=> [#CustomField1, #CustomField2, ...]
    def collection
      symbols.collect{|k,v| v}.sort{|a,b| a.symbol <=> b.symbol}
    end

    #   CustomFields::NoneAlphaNumeric.find(symbol) -> #CustomFields::NoneAlphaNumeric
    # Get custom field object by finding symbol
    #   CustomFields::NoneAlphaNumeric.find('!') #=> #CustomFields::NoneAlphaNumeric
    #   CustomFields::NoneAlphaNumeric.find('') #=> nil
    #   CustomFields::NoneAlphaNumeric.find(nil) #=> nil
    def find(symbol)
      symbols[symbol]
    end

    private
    def symbols
      @@cached_symbols ||= {}

      list_symbols.each do |k, v|
        @@cached_symbols[k] = CustomFields::NoneAlphaNumeric.new(k, v)
      end if @@cached_symbols.empty?

      @@cached_symbols
    end

    def list_symbols
      {
        '@' => '',
        '!' => '',
        '*' => '',
        '+' => '',
        '.' => '',
        ',' => '',
        '/' => '',
        '(' => '',
        ')' => '',
        '-' => '',
        '%' => '',
        '&' => '',
        ':' => '',
        ';' => '',
        '<' => '',
        '=' => '',
        '>' => '',
        '?' => '',
        '[' => '',
        ']' => '',
        '_' => '',
        '|' => ''
      }
    end
  end

  def initialize(symbol, descr)
    @symbol = symbol
    @descr = descr
  end
end
