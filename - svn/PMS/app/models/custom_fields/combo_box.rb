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
#   cell.value = '1'
class CustomFields::ComboBox < CustomField

  class << self
    #   CustomFields::ComboBox.name_prefix -> string
    #
    # Get the default name prefix
    #   CustomFields::ComboBox.name_prefix #=> cmb
    def name_prefix
      'cmb'
    end

    #   CustomFields::ComboBox.cell_label_ids(String) -> int
    #
    # Get the label id
    #   CustomFields::ComboBox.cell_label_id('1')  #=> 1
    #   CustomFields::ComboBox.cell_label_id(nil)  #=> 0
    def cell_label_id(cell_value)
      cell_value.to_i
    end
  end #end class << self

  def search_value?(value, filter)
    return true if filter.nil?

    label_id = CustomFields::ComboBox.cell_label_id(value).to_s

    case filter[:selected_ids]
    when Array
      filter[:selected_ids].include?(label_id)
    else
      !filter[label_id].nil?
    end
  end

  def description
    'combo'
  end

  def absolute_value(cell_value)
    cell_label_id = CustomFields::ComboBox.cell_label_id(cell_value)

    Label.find(cell_label_id) if cell_label_id > 0
  end

  def text(cell_value)
    cell_label = absolute_value(cell_value)
    if cell_label
      cell_label.descr
    elsif cell_value == ''
      ''
    else
      cell_label_id = CustomFields::ComboBox.cell_label_id(cell_value)
      Label.missing_msg(cell_label_id)
    end
  end

  def parse(value, options={})
    label_id = nil
    
    self.labels.each do |l|
      label_id = l.id if l.descr == value

      break if label_id
    end

    raise "Unable to find '#{value}' in '#{self.label_descr}'" if label_id.nil?

    label_id
  end

  def label_ids
    self[:value] ||= {}
    self[:value][:label_ids] ||= []
    
    @label_ids ||= self[:value][:label_ids].collect{|l_id| l_id.to_i if l_id.to_i > 0 }.compact
  end

  def labels
    label_ids.collect{|l_id| Label.find(l_id) if l_id> 0 }.compact
  end
  
  def default_value
    self[:value] ||= {}
    self[:value][:default_value] = self[:value][:default_value].to_i unless self[:value][:default_value].to_s.empty?
    self[:value][:default_value]
  end
  
end

#    content = retrieve_multi_result(@gen_rows[row.id][cf.id])