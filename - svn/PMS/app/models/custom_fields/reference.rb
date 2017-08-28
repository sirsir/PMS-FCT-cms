# Stored value structure
#
# <b>CustomField</b>
#   custom_field.value = {
#       :screen_id => '1',
#       :custom_field_ids => ['1', '2', '3', ...],
#       :control_type => 'combo_box'/'searchable_text'
#     }
#
# <b>Field</b>
#   field.value = {
#       :relate_to => '1',
#       :related_from => '2'
#     }
#
# <b>Cell</b>
#   cell.value = {
#       :row_id => '1',
#       '20' => "Field ID 20's value",
#       '21' => "Field ID 21's value",
#       '22' => "Field ID 22's value"
#     }
#
class CustomFields::Reference < CustomField
  # belongs_to :screen, :foreign_key => self[:value][:screen_id]

  class << self
    def row_in_use?(row_id, cells, all = false)
      row_in_use_by = []
      
      cells.each do |c|
        row_in_use_by << c.row if c.value[:row_id].to_i == row_id
        break unless all || row_in_use_by.empty?
      end

      all ? row_in_use_by : row_in_use_by.first
    end

    #   CustomFields::Reference.field_related_to(Hash)  -> int
    #
    # Get the value for the :relate_to key
    #   CustomFields::Reference.field_related_to({:relate_to => 1}) #=> 1
    #   CustomFields::Reference.field_related_to({})                #=> 0
    #   CustomFields::Reference.field_related_to(nil)               #=> 0
    def field_related_to(field_value)
      field_value ||= {}

      field_value[:relate_to].to_i
    end

    #   CustomFields::Reference.field_related_from(Hash) -> int
    #
    # Get the value for the :related_from key
    #   CustomFields::Reference.field_related_from({:related_from => 1}) #=> 1
    #   CustomFields::Reference.field_related_from({})                   #=> 0
    #   CustomFields::Reference.field_related_from(nil)                  #=> 0
    def field_related_from(field_value)
      field_value ||= {}

      field_value[:related_from].to_i
    end

    #   CustomFields::Reference.cell_ref_row_id(String/Fixnum) -> int
    #
    # Get the value
    #   CustomFields::Reference.cell_ref_row_id({:row_id => '1'}) #=> 1
    #   CustomFields::Reference.cell_ref_row_id({})               #=> 0
    #   CustomFields::Reference.cell_ref_row_id(nil)              #=> 0
    def cell_ref_row_id(cell_value)
      case cell_value
      when Fixnum
        cell_value
      when Cell
        cell_ref_row_id(cell_value.value)
      else
        cell_value ||= {}

        cell_value[:row_id].to_i
      end
    end

    def relation_row_ids(row_id, cells)
      cells.collect{|c| c.row_id if cell_ref_row_id(c.value) == row_id }.compact
    end

    #   CustomFields::Reference.find_all -> array
    # Get all CustomFields::Reference
    #   CustomFields::Reference.find_all #=> [#CustomField1, #CustomField2, ...]
    def find_all
      @@all_custom_field_references = nil unless CustomField.instance_cached?
      @@all_custom_field_references ||= CustomFields::Reference.find(:all)
      
      @@all_custom_field_references.clone
    end

    # The number of maximum items to show in the dropdown
    def dropdown_limit
      50
    end
  end #end class << self

  def search_value?(value, filter)
    return true if filter.nil?
    
    filter_id = CustomFields::Reference.cell_ref_row_id(filter)
    if filter_id == 0 && (filter.is_a?(Hash) && !filter.has_key?(:selected_ids))
      true
      #    elsif self.searchable_text?
      #      (Row.find(value.to_i).description.include?(filter)) unless value.to_s.empty?
    else
      ref_row_id = CustomFields::Reference.cell_ref_row_id(value)
      case filter[:selected_ids]
      when Array
        filter[:selected_ids].any?{|r_id| r_id.to_i > 0 && r_id.to_i == ref_row_id }
      else
        filter_id == ref_row_id
      end
    end
  end

  #   custom_field.screen_id -> integer
  # Get screen id
  #   custom_field.screen_id #=> 189
  def screen_id
    self[:value] ||= {}
    self[:value][:screen_id].to_i
  end

  #   custom_field.screen -> screen's object
  # Get screen's object
  #   custom_field.screen #=> #Screen
  def screen
    Screen.find(screen_id) if Screen.exists?(screen_id)
  end

  #~ ToDo: Remove unused custom_field_ids, coz using row.description for drop down values
  #   custom_field.custom_field_ids -> array
  # Get custom field ids that was been set in custom field
  #   custom_field.custom_field_ids #=> []
  def custom_field_ids
    @custom_field_ids ||= if self.is_separate_controls?
      self.screen.fields.collect{|f| f.custom_field_id if f.is_mandatory? && f.is_a?(Fields::Data)}.compact
    else
      self[:value][:custom_field_ids] ||= []
      self[:value][:custom_field_ids].collect{|cf_id| cf_id.to_i if cf_id.to_i > 0 }.compact
    end
  end

  #   custom_field.custom_fields -> array
  # Get custom field's objects that was been set in custom field
  #   custom_field.custom_fields #=> []
  def custom_fields
    custom_field_ids.collect{|cf_id| CustomField.find(cf_id)}
  end
  
  alias_method :descr_custom_field_ids, :custom_field_ids
  alias_method :descr_custom_fields, :custom_fields

  #   custom_field.control_type -> string
  # Get control type
  #   custom_field.control_type #=> "combo_box"
  def control_type
    self[:value][:control_type].to_s
  end

  #   custom_field.descr_separator -> string
  # Get description separator, notes a return value is " - "
  #   custom_field.descr_separator #=> " - "
  def descr_separator
    ' - '
  end

  #   custom_field.searchable_text? -> integer/nil
  # Check that control type is searchable text or not.
  # Force the CustomField to display as a searchable_text, if the
  # referred screen has more then 50 rows
  # if return value is integer that mean true
  #   custom_field.searchable_text? #=> nil
  def searchable_text?
    @is_searchable_text ||= control_type =~ /searchable_text/ #~ || screen.rows.count > CustomFields::Reference.dropdown_limit
  end

  alias_method :is_searchable_text?, :searchable_text?

  def description
    'List of master screens'
  end
  
  def validate_value(cell_value, options = {})
    cell_value ||= {}
    cell_value.keys.each do |k|
      if k.to_s =~ /row_id/
      else
        field_id = k.to_i
        if Field.exists?(field_id)
          field = Field.find(field_id)
          case field
          when Fields::ReferenceAttribute, Fields::CodeCombindedReferenceAttribute
            cell_value[k] = field.validate_value(cell_value[k])
          end
        end
      end
    end if cell_value.is_a?(Hash)

    cell_value
  end
  
  #   custom_field.absolute_value(cell_value)  -> an_hash
  # Get the hash structed object
  #   #=> {
  #     :row => Row,
  #     field_id_1 => "Field 1's value",
  #     field_id_2 => "Field 2's value",
  #     field_id_3 => "Field 3's value"
  #    }
  def absolute_value(cell_value)
    cell_value = nil if cell_value.is_a?(String)
    cell_value ||= { :row_id => nil }
    result = cell_value.clone
    ref_row_id = CustomFields::Reference.cell_ref_row_id(cell_value)
    if ref_row_id > 0
      result[:row] = Row.find(ref_row_id) if Row.exists?(ref_row_id)
      result.delete(:row_id)
    end
    result
  end
  
  def text(cell_value)
    reference_row = absolute_value(cell_value)[:row]
    descr_custom_field_ids = [self.value[:custom_field_ids]].flatten.compact.select{|i| i.to_i>0}
    reference_row.nil? ?  '' : reference_row.description(descr_custom_field_ids)
  end
  
  def evaluate_value(row)
    custom_field_ids.collect{|cf_id|
      cell = row.cell( cf_id )
      cell.to_text unless cell.nil?
    }.compact
  end

  def key_value(cell_value)
    cell_value[:row_id]
  end

  def parse(value, options={})
    unique_fields = self.screen.unique_fields

    if self.custom_field_ids.empty?
      descr_custom_field_ids = unique_fields.collect{|f| f.custom_field_id }

      raise "Unique fields not set for screen '#{self.screen.label_descr}'" if descr_custom_field_ids.empty?
    else
      descr_custom_field_ids = self.descr_custom_field_ids
    end
    
    row_id = nil

    unless value.to_s.strip.empty?
      row_ids = self.screen.index_lookup([value], descr_custom_field_ids)
      rows = Row.find(row_ids)
      
      matched_rows = rows.select do |r|
        r.description(descr_custom_field_ids) =~ /^#{value}$/i
      end

      raise "Multiple rows match the value '#{value}' in Screen '#{self.screen.label_descr}'" if matched_rows.size > 1

      row_id = matched_rows.first.id if matched_rows.size == 1
      
      raise "Unable to find '#{value}' in Screen '#{self.screen.label_descr}'" if row_id.nil?
    end

    { :row_id => row_id.to_i }
  end

  def is_empty?(cell_value)
    CustomFields::Reference.cell_ref_row_id(cell_value) == 0
  end

  def is_separate_controls?
    @is_separate_controls ||= control_type =~ /separate_controls/
  end

  def is_combo_box?
    @is_combo_box ||= !(is_searchable_text? || is_separate_controls?)
  end

end

#content = @gen_values[@gen_rows[row.id][cf.id].to_s]
