# Stored value structure
#
# <b>CustomField</b>
#   custom_field.value = {
#       :label_ids => ['-1', '1', '2', ...]
#     }
#
# <b>Field</b>
#   field.value = nil
#
# <b>Cell</b>
#   Non selected
#   cell.value = ['-1']
#
#   Single Selected
#   cell.value = ['-1', '1']
#
#   Multi Selected
#   cell.value = ['-1', '1', '2', '3']
class CustomFields::ListBox < CustomField

  class << self
    #   CustomFields::ListBox.name_prefix -> string
    #
    # Get the default name prefix
    #   CustomFields::ListBox.name_prefix #=> lst
    def name_prefix
      'lst'
    end

    #   CustomFields::ListBox.cell_label_ids(Array) -> an_array
    #
    # Get the label ids check status
    #   cell_value = ['-1', '1', '2', '3']
    #
    #   CustomFields::ListBox.cell_label_ids(cell_value)  # => [1, 2, 3]
    #   CustomFields::ListBox.cell_label_ids([])          # => []
    #   CustomFields::ListBox.cell_label_ids(nil)         # => []
    def cell_label_ids(cell_value)
      cell_value ||= []

      cell_value.collect do |v|
        v.to_i if v.to_i > 0
      end.compact
    end
  end

  def description
    'A single select list with a configurable list of options.'
  end

  #   custom_fiels.label_ids -> array
  # Get array that contain label id
  #   custom_field.label_ids #=> [1,2,3]
  def label_ids
    self[:value][:label_ids] ||= []
    @label_ids ||= self[:value][:label_ids].collect{|l_id| l_id.to_i if l_id.to_i > 0 }.compact
  end

  #   custom_fiels.labels -> array
  # Get array that contain label object
  #   custom_field.labels #=> [#Label, #Label, #Label]
  def labels
    label_ids.collect{|l_id| Label.find(l_id) if l_id> 0 }.compact
  end

  #   custom_field.default_value -> integer
  # Get defaul value, notes value is label id
  #   custom_field.default_value #=> 675
  def default_value
    self[:value] ||= {}
    self[:value][:default_value] = self[:value][:default_value].to_i unless self[:value][:default_value].to_s.empty?
    self[:value][:default_value]
  end

  def multi_value?
    false
  end

  #   custom_field.absolute_value(cell_value) -> an_array of Label state hash
  #
  #   custom_field.labels #=> [label_1, label_2, label_3, ...]
  #   custom_field.absolute_value( [-1, 1, 2, 3] )  #=> [label_1, label_2,label_3, ...]
  def absolute_value(cell_value)
    cell_label_ids = CustomFields::ListBox.cell_label_ids(cell_value)
    cell_label_ids.collect{ |label_id| Label.find(label_id) }
  end

  #   custom_field.text(cell_value) -> string
  # Get text to display in screen
  #   custom_field.text('675') #=> "Bangkok"
  def text(cell_value)
    texts(cell_value).join(', ')
  end

  #   custom_field.html(cell_value) -> string
  # Get string that contain html tag to display in screen
  #   custom_field.html('675') #=> "Bangkok"
  def html(cell_value)
    if multi_value?
      prefix = '<li class="check_box_true"><span>'
      postfix = '</span></li>'
    end

    texts(cell_value).collect{|t| "#{prefix}#{t}#{postfix}" }.join
  end

  def parse(value, options={})
    value =" #{value} "

    label_ids = self.labels.collect do |l|
      if value =~ / #{l.descr} /i
        value.gsub!(/#{l.descr} /i, '')
        
        l.id
      end
    end.compact

    raise "Unable to find '#{value}' in '#{self.label_descr}'" unless value.strip.empty?

    label_ids
  end

  private

  def texts(cell_value)
    cell_labels = absolute_value(cell_value)
    cell_labels.collect{|cl| cl.descr.to_s }.compact
  end

end
