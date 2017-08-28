class CustomFields::UploadFile < CustomField

  class << self

    #   CustomFields::UploadFile.name_prefix -> string
    #
    # Get the default name prefix
    #   CustomFields::UploadFile.name_prefix #=> fil
    def name_prefix
      'fil'
    end
  end

  def search_value?(value, filter)
    return true if filter.nil?

    value.empty? ^ (filter == 'uploaded')
  end
  
  def description
    'Upload File'
  end

  #   custom_field.description -> string
  # Get description based on options that has been set in custom field
  #   custom_field.description #=> "Upload File html, xml, txt, csv <=128 KB"
  def description
    des_file_type = file_type.collect{|k,v| k if v && k.to_i >= 0 }.compact.join(', ')
    "Upload File #{des_file_type} <=#{max_size.to_s} KB"
  end

  #   custom_field.file_type -> hash
  # Get file types, which this upload is supported
  #   custom_field.file_type #=> {"html"=>"true", "xml"=>"true", "-1"=>"false", "txt"=>"true", "csv"=>"true"}
  def file_type
    option[:file_type]
  end

  #   custom_field.max_size -> string
  # Get maximum size of file that allow to upload
  #   custom_field.max_size #=> "128"
  def max_size
    option[:max_size]
  end

  #   custom_field.option -> hash
  # Get options that has been set in cusotm field
  #   custom_field.option #=> {"file_type"=>   {"html"=>"true", "xml"=>"true", "-1"=>"false", "txt"=>"true", "csv"=>"true"},  "max_size"=>"128"}
  def option
    self[:value] ||= {}
    self[:value][:option] ||= {}

    self[:value][:option][:file_type] ||= {}

    self[:value][:option][:max_size] = nil if self[:value][:option][:max_size].to_i <= 0
    self[:value][:option][:max_size] ||= 128 # KByte

    self[:value][:option]
  end

  def parse(value, options={})
    #~ ToDo: The path to the file is required.
    # And the file has to be uploaded to the server
    super
  end

end
