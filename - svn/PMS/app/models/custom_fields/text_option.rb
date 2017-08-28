class CustomFields::TextOption
  attr_accessor :name
  attr_accessor :descr
  attr_accessor :display_seq

  class << self

    #   CustomFields::TextOption.option_collection -> array
    # Get text options, a return value is array that contain #CustomField
    #   CustomFields::TextOption.option_collection #=> [#CustomField1, #CustomField2, ...]
    def option_collection
      text_options.collect{|k, v| v }.sort{|a, b| a.display_seq <=> b.display_seq}
    end

    private

    def text_options
      @@cached_text_options ||= {}

      list_text_options.each do |k, v|
        cf = CustomFields::TextOption.new
        cf.name = k
        cf.descr = v[:descr]
        cf.display_seq = v[:seq]

        @@cached_text_options[k] = cf
      end if @@cached_text_options.empty?

      @@cached_text_options
    end

    def list_text_options
      {
        :length => {:seq => 1, :descr => 'Length of Characters'},
        :alphabet => {:seq => 2, :descr => 'Alphabet Characters'},
        :numeric => {:seq => 3, :descr => 'Numerical Characters'},
        :symbols => {:seq => 4, :descr => 'Non-alphanumeric Characters'},
        :non_english => {:seq => 5, :descr => 'Non-English Characters'}
      }
    end
  end
end
