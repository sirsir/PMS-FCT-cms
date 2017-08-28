class CustomFields::UploadImage < CustomField

  class << self

    #   CustomFields::UploadImage.name_prefix -> string
    #
    # Get the default name prefix
    #   CustomFields::UploadImage.name_prefix #=> img
    def name_prefix
      'img'
    end

    def image_templates
      {
        :business_card => '300x165',
        :photo => '280x350',
        :signature => '250x80',
        :free_size => '0x0'
      }
    end
  end

  def search_value?(value, filter)
    return true if filter.nil?

    value.empty? ^ (filter == 'uploaded')
  end

  #   custom_field.description -> string
  # Get description
  #   custom_field.description #=> "Upload Image jpg, gif, png <=250 KB"
  def description
    des_file_type = file_type.collect{|k,v| k if v && k.to_i >= 0 }.compact.join(', ')
    "Upload Image #{des_file_type} <=#{max_size.to_s} KB"
  end

  #   custom_field.file_type -> hash
  # Get file types, which this upload is supported or not
  #   custom_field.file_type #=> {"jpg"=>"true", "-1"=>"false", "gif"=>"true", "png"=>"true"}
  def file_type
    option[:file_type]
  end

  #   custom_field.max_size -> string
  # Get maximum size that this upload is support (KB)
  #   custom_field.max_size #=> "250"
  def max_size
    option[:max_size]
  end

  #   custom_field.dimensions -> string
  # Get dimensions that this upload is support
  #   custom_field.dimensions #=> "250"
  def dimensions
    option[:dimensions]
  end

  #   custom_field.option -> hash
  # Get option that has been set in cusotm field
  #   custom_field.option #=> {"file_type"=>{"jpg"=>"true", "-1"=>"false", "gif"=>"true", "png"=>"true"},  "dimensions"=>"0x0",  "max_size"=>"250"}
  def option
    self[:value] ||= {}
    self[:value][:option] ||= {}

    self[:value][:option][:file_type] = nil if (self[:value][:option][:file_type] || {}).empty?
    self[:value][:option][:file_type] ||= {}

    self[:value][:option][:max_size] = nil if self[:value][:option][:max_size].to_i <= 0
    self[:value][:option][:max_size] ||= 128 # KByte

    self[:value][:option][:dimensions] = nil if self[:value][:option][:dimensions].to_s.empty?
    self[:value][:option][:dimensions] ||= CustomFields::UploadImage.image_templates[:free_size] # "0x0"

    self[:value][:option]
  end

 

  def html(cell_value)
    if dimensions =~ /x/ && dimensions != CustomFields::UploadImage.image_templates[:free_size]
      d = dimensions.split('x')
      width = d.first.to_i
      height = d.last.to_i

      ratio = [20.to_f / height, 1].min
      width *= ratio
      height *= ratio
    else
      width = height = '100%'
    end
    
    cell_value.empty? ? '&nbsp;' : "<img src=\"/attachments/#{cell_value}\" width=\"#{width}\" height=\"#{height}\">"
  end

  def parse(value, options={})
    #~ ToDo: The mapping to the label is required
    super
  end

end