class CustomFields::Password < CustomField

  class << self

    #   CustomFields::Password.name_prefix -> string
    #
    # Get the default name prefix
    #   CustomFields::Password.name_prefix #=> pwd
    def name_prefix
      'pwd'
    end
  end

  def description
    'A basic single line text box custom field to allow password input.'
  end
  
  def parse(value, options={})
    #~ ToDo: Passwords need to be encrypt
    super
  end
end

#    content = "<b>******</b>"