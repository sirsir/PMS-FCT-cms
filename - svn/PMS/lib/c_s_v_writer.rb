#　CSV

module CSVWriter

  # To use this module, the following method needs to
  # be defined
  #
  #   # Headers
  #   def csv_header_data
  #     [
  #       [ ]
  #     ]
  #   end
  #
  #   # Field descriptions
  #   def csv_field_descr
  #     { }
  #   end
  #
  #   # The displaying order when genarating the CSV
  #   def csv_field_sequence
  #     [ ]
  #   end
  #
  #   # The data that will be written to the csv_field_sequence
  #   def csv_data_collection
  #     [
  #       [ ]
  #     ]
  #   end

  # Store the data in a csv format
  def to_csv

    csv_data_utf8 = ''

    CSV::Writer.generate(csv_data_utf8, ?,) { |writer|
      csv_header_data.each do |header|
        writer << header
      end

      writer << csv_field_sequence.collect{|field| csv_field_descr[ field ].gsub(/[^\w]/,'_').gsub(/[_]+/,'_').underscore }

      csv_data_collection.each do |data|
        writer << data
      end
    }

    csv_data_utf8 = replace_invalid_csv_contents(csv_data_utf8)

    # ToDo: To support correct JP char exporting
    # the text must be convert to the correct encoding
    #   String.safe_iconv(csv_data_utf8)
    
    csv_data_utf8
  end

  def save_to_csv(local_filename, options = {})
    defaults = {
      :palette => []
    }
    options = defaults.merge(options)
    
    File.open(local_filename, 'w') do |f|
        f.print to_csv
    end
  end

  protected

  # The list of string to replace in the CSV data
  def csv_replacements
    replacements = [
        [/\r\n/ , "\n"]
      ]

    replacements
  end

  # The list of string to replace in the CSV data
  # until nothing is found
  def csv_multi_replacements
    [
      [/\n\n/ , "\n"]
    ]
  end

  private

  # Remove invalid contents in the specified CSV data
  def replace_invalid_csv_contents(csv_data)

    csv_replacements.each do |replacement|
      csv_data.gsub!( replacement[0] , replacement[1] )
    end

    csv_multi_replacements.each do |replacement|
      while !csv_data.index(replacement[0]).nil? do
        csv_data.gsub!(replacement[0] , replacement[1])
      end
    end

    csv_data.strip!

    csv_data
  end
end
