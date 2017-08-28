# Stored value structure
#
# <b>CustomField</b>
#   custom_field.value = {
#       :screen_id => '1'
#     }
#
# <b>Field</b>
#   field.value = {
#       :relate_to => '1',
#       :related_from => '2'
#     }
#
# <b>Cell</b>
#   cell.value = ['1', '2', '3', ...]
class CustomFields::LeftRight < CustomField

  class << self
    #   CustomFields::LeftRight.field_related_to(Hash)  -> int
    #
    # Get the value for the :relate_to key
    #   CustomFields::LeftRight.field_related_to({:relate_to => 1}) #=> 1
    #   CustomFields::LeftRight.field_related_to({})                #=> 0
    #   CustomFields::LeftRight.field_related_to(nil)               #=> 0
    def field_related_to(field_value)
      field_value ||= {}

      field_value[:relate_to].to_i
    end

    #   CustomFields::LeftRight.field_related_from(Hash) -> int
    #
    # Get the value for the :related_from key
    #   CustomFields::LeftRight.field_related_from({:related_from => 1}) #=> 1
    #   CustomFields::LeftRight.field_related_from({})                   #=> 0
    #   CustomFields::LeftRight.field_related_from(nil)                  #=> 0
    def field_related_from(field_value)
      field_value ||= {}

      field_value[:related_from].to_i
    end

    #   CustomFields::LeftRight.cell_ref_row_id(Array) -> an_array of int
    #
    # Get the value
    #   CustomFields::LeftRight.cell_ref_row_ids(['1', '2', '3', ...])  #=> [1, 2, 3, ...]
    #   CustomFields::LeftRight.cell_ref_row_ids([]])                   #=> []
    #   CustomFields::LeftRight.cell_ref_row_ids(nil)                   #=> []
    def cell_ref_row_ids(cell_value)
      cell_value ||= []
      
      if cell_value.is_a?(Hash) && cell_value.has_key?(:selected_ids)
        cell_value = cell_value[:selected_ids]
      end
      
      cell_value.collect{|r_id| r_id.to_i if r_id.to_i > 0 }.compact
    end
    
    def relation_row_ids(row_id, cells)
      cells.collect{|c| c.row_id if cell_ref_row_ids(c.value).include?(row_id) }.compact
    end
  end #end class << self

  def search_value?(value, filter)
    return true if filter.nil?

    filter_ids  = CustomFields::LeftRight.cell_ref_row_ids(filter)
    if filter_ids.empty?
      true
    else
      ref_row_ids  = CustomFields::LeftRight.cell_ref_row_ids(value)
      !(filter_ids & ref_row_ids).empty?
    end
  end

  def description
    'Left Right'
  end

  #   custom_field.absolute_value(cell_value) -> array
  # Get absolute value
  #   custom_field.absolute_value(cell_value) #=> [#Row, #Row, ...]
  def absolute_value(cell_value)
    ref_row_ids = CustomFields::LeftRight.cell_ref_row_ids(cell_value)
    Row.find(ref_row_ids)
  end

  def text(cell_value)
    reference_rows = absolute_value(cell_value)
    reference_rows.collect{|r| r.description }.join(', ')
  end

  def html(cell_value)
    reference_rows = absolute_value(cell_value)
    reference_rows.collect{|r| "<li class='check_box_true'><span>#{r.description}</span></li>" }.join()
  end

  def parse(value, options={})
    value =" #{value} "
    
    custom_field_ids = self.screen.unique_fields.collect{|f| f.custom_field_id }

    raise "Unique fields not set for screen '#{self.screen.label_descr}'" if custom_field_ids.empty?

    row_ids = self.screen.rows.collect do |r|
      row_descr = r.description(custom_field_ids)

      if value =~ / #{row_descr} /i
        value.gsub!(/#{row_descr} /i, '')

        r.id
      end
    end.compact

    raise "Unable to find '#{value}' in Screen '#{self.screen.label_descr}'" unless value.strip.empty?

    row_ids
  end

  #   custom_field.screen_id -> integer
  # Get screen id that has been set in custom field
  #   custom_field.screen_id #=> 1
  def screen_id
    self[:value][:screen_id].to_i
  end

  #   custom_field.screen -> screen_object
  # Get screen that has been set in custom field
  #   custom_field.screen #=> #Screen
  def screen
    Screen.find(screen_id)
  end

  #   custom_field.default_value -> array
  # Get default value
  #   custom_field.defualt_value #=> ["-1"]
  def default_value
    self[:value] ||= {}
    self[:value][:default_value] ||= []
    self[:value][:default_value]
  end

end

#    content = @gen_values[@gen_rows[row.id][cf.id].join(",")]