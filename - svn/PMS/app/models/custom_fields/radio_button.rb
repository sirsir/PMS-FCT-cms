# Stored value structure
#
# <b>CustomField</b>
#   custom_field.value = {
#       :new_line => 'true',
#       :label_ids => ['-1', '1', '2', ...]
#     }
#
# <b>Field</b>
#   field.value =nil
#
# <b>Cell</b>
#   cell.value = {
#       :label => '1',
#       :other_value => 'Abc'
#     }
class CustomFields::RadioButton < CustomField

  class << self

    #   CustomFields::RadioButton.name_prefix -> string
    #
    # Get the default name prefix
    #   CustomFields::RadioButton.name_prefix #=> rad
    def name_prefix
      'rad'
    end

    #   CustomFields::RadioButton.cell_label_id(Hash) -> an_hash
    #
    # Get the value for the :label key
    #   CustomFields::RadioButton.cell_label_id({:label => '1'})  #=> 1
    #   CustomFields::RadioButton.cell_label_id({})               #=> 0
    #   CustomFields::RadioButton.cell_label_id(nil)              #=> 0
    def cell_label_id(cell_value)
      case cell_value
      when Cell
        cell_label_id(cell_value.value)
      when String, Fixnum
        cell_value.to_i
      else
        cell_value ||= {}

        cell_value[:label].to_i
      end
    end

    # Get the value for the :label key
    #   CustomFields::RadioButton.label_ids({:label => '1'})  #=> 1
    #   CustomFields::RadioButton.label_ids({})               #=> 0
    #   CustomFields::RadioButton.label_ids(nil)              #=> 0
    def cell_label_ids(cell_value)
      cell_value ||= {}
      cell_value[:label_ids] ||= []
      cell_value[:label_ids].collect{|l_id| l_id.to_i if l_id.to_i > 0 }.compact || []
    end

    def cell_label(cell_value)
      label_id = cell_label_id(cell_value)

      if label_id > 0
        Label.find(label_id)
      else
        Label.missing_msg(label_id)
      end
    end
  end #end class << self

  def search_value?(value, filter)
    return true if filter.nil?

    label_id = CustomFields::RadioButton.cell_label_id(value).to_s

    case filter[:selected_ids]
    when Array
      filter[:selected_ids].include?(label_id)
    else
      !filter[label_id].nil?
    end
  end
  
  def description
    'A list of radio buttons'
  end


  #   custom_field.absolute_value(cell_value) -> Label
  # Get absolute value, a return value is label object
  #   custom_field.absolute_value({:label => '620'}) #=> #Label
  #   custom_field.absolute_value({}) #=> nil
  #   custom_field.absolute_value(nil) #=> nil
  def absolute_value(cell_value)
    if CustomFields::RadioButton.cell_label_id(cell_value) == other_label_id
      other_value(cell_value)
    else
      cell_label_id = CustomFields::RadioButton.cell_label_id(cell_value)

      Label.find(cell_label_id) if cell_label_id > 0
    end
  end

  #   custom_field.text(cell_value) -> string
  # Get string to display on screen
  #   custom_field.text({:label => '620'}) #=> "Numeric 1"
  #   custom_field.text({}) #=> ""
  #   custom_field.text(nil) #=> ""
  def text(cell_value)
    cell_label = absolute_value(cell_value)
    if cell_label
      cell_label.descr
    else
      cell_label_id = CustomFields::RadioButton.cell_label_id(cell_value)
      Label.missing_msg(cell_label_id)
    end
  end

  #   custom_field.html(cell_value) -> string
  # Get string to display on screen
  #   custom_field.html({:label => '620'}) #=> "Numeric 1"
  #   custom_field.html({}) #=> "<span class='error_message'>Label with ID=0 is missing!</span>"
  #   custom_field.html(nil) #=> "<span class='error_message'>Label with ID=0 is missing!</span>"
  def html(value)
    if other_label_id == CustomFields::RadioButton.cell_label_id(value)
      label = CustomFields::RadioButton.cell_label(value)
      label.is_a?(Label) ? label.descr : label
    else
      value_label = absolute_value(value)
      label_descr =  value_label.nil? ? Label.missing_msg(CustomFields::RadioButton.cell_label_id(value)) : value_label.descr

      label_descr
    end
  end

  def parse(value, options={})
    label_id = nil
    
    self.labels.each do |l|
      label_id = l.id if l.descr == value

      break if label_id
    end

    raise "Unable to find '#{value}' in '#{self.label_descr}'" if label_id.nil?

    { :label => label_id }
  end

  #   custom_field.label_ids -> array
  # Get label ids that have been set in custom field
  #   custom_field.label_ids #=> [620, 621]
  def label_ids
    self[:value] ||= {}
    self[:value][:label_ids] ||= []
    @label_ids ||= (self[:value][:label_ids]+ [other_label_id]).collect{|l_id| l_id.to_i if l_id.to_i > 0 }.compact
  end

  #   custom_field.labels -> array
  # Get label objects that have been set in custom field
  #   custom_field.labels #=> [#Label, #Label]
  def labels
    label_ids.collect{|l_id| Label.find(l_id) if l_id> 0 }.compact
  end

  #   custom_field.new_line? -> true/false
  # Check that custom field was been set new line option or not
  #   custom_field.new_line? #=> flase
  def new_line?
    self[:value] ||= {}
    @new_line ||= CustomFields::CheckBox.true_or_false?(self[:value][:new_line])
  end

  #   custom_field.default_value -> integer
  # Get default value, a return value is label id
  #   custom_field.default_value -> 620
  def default_value
    self[:value] ||= {}
    self[:value][:default_value].to_i
  end

  def other_label_id
    self[:value] ||= {}
    self[:value][:other_label_id].to_i
  end

  def other_value(cell_value)
    cell_value[:other_value].to_s
  end

  #   custom_field.evaluate_default_value(options = {}) -> hash
  # Get evaluate default value
  #   custom_field.evaluate_default_value() #=> {:label=>620}
  def evaluate_default_value(options = {})
    @evaluate_default_value ||= { :label => default_value }
    @evaluate_default_value.delete_if { |k,v| v <= 0 }

    @evaluate_default_value
  end
end

#    content = retrieve_radiobox_result(@gen_rows[row.id][cf.id])
