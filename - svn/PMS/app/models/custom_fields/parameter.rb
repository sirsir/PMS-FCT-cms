# Stored value structure
#
# <b>CustomField</b>
#   custom_field.value = {
#       :date_from_id => 1,
#       :date_to_id => 2,
#       :field_id => 3
#       :screen_id => 3
#     }
#
# <b>Field</b>
#   field.value = {
#       :field_id => '3',
#       :related_from => '2'
#     }
#
# <b>Cell</b>
#   cell.value = 0.5
class CustomFields::Parameter < CustomField

  class << self

    #   CustomFields::Parameter.name_prefix -> string
    #
    # Get the default name prefix
    #   CustomFields::Parameter.name_prefix #=> param
    def name_prefix
      'param'
    end

    def field_id(field_value)
      field_value[:field_id]
    end

    def date_time_field(field_value)
      Field.find(field_id(field_value))
    end
    
  end # class << self

  def search_value?(value, filter)
    return true if filter.nil?

    value.to_s.downcase.include?(filter.to_s.downcase)
  end
  
  # row.cell(custom_field_id) => cell value
  def evaluate_value(date_value)
    date_value = date_value.to_date
    value = 0
    screen.rows.each do |r|
      actual_row = Field.row_by_field(parameter_field, r)
      if date_value >= actual_row.cell(date_from_field.custom_field_id).absolute_value.to_date and
          date_value <= actual_row.cell(date_to_field.custom_field_id).absolute_value.to_date
        cell = actual_row.cell(parameter_field.custom_field_id)
        value = cell.value unless cell.nil?
      end unless actual_row.nil?
    end
    value
  end

  def description
    'Parameter'
  end

  def special_values(screen)
    fields
  end

  def label_ids
    self[:value][:label_ids] ||= []
    @label_ids ||= self[:value][:label_ids].collect{|l_id| l_id.to_i if l_id.to_i > 0 }.compact
  end

  def labels
    label_ids.collect{|l_id| Label.find(l_id) }
  end

  def text(cell_value)
    cell_value.to_s
  end

  def html(value)
    #    options = value[:options]
    #    row_code = Row.find(value[:scr_row_id].to_i)
    #
    #    result = [row_code.screen_combined_code]
    #
    #    options.each do |o|
    #      result << [row_selected(o[1][:row_ids])]
    #    end
    #    result
    value
  end

  def parse(value, options={})
    #~ ToDo: Need to convert the value to some value related to the param
    super
  end

  def screen_id
    self.value[:screen_id].to_i
  end
  
  def parameter_field_id
    self.value[:field_id].to_i
  end
  
  def date_from_id
    self.value[:date_from_id].to_i
  end
  
  def date_to_id
    self.value[:date_to_id].to_i
  end
  
  def screen
    Screen.find(screen_id)
  end
  
  def parameter_field
    Field.find(parameter_field_id)
  end
  
  def date_from_field
    Field.find(date_from_id)
  end
  
  def date_to_field
    Field.find(date_to_id)
  end

  def default_value
    self[:value] ||= {}
    self[:value][:default_value] ||= 'empty'
    self[:value][:default_value]
  end
  
  def evaluate_default_value(options = {})
    value = 0
    unless options[:row].nil? && options[:field].nil?
      dt_value = options[:row].cell(options[:field].source_field.custom_field_id).value
      unless dt_value.nil?
        value = evaluate_value(dt_value)
      end
    end
    value
  end
end
