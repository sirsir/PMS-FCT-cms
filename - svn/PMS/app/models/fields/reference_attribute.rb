class Fields::ReferenceAttribute < Field

  class << self
    #   Fields::Fields::ReferenceAttribute.cell_ref_att_value(String/Fixnum) -> int
    #
    # Get the value
    #   CustomFields::Reference.cell_ref_row_id('1') #=> 1
    #   CustomFields::Reference.cell_ref_row_id(nil) #=> 0
    def cell_ref_att_value(cell_value)
      cell_value[self.id.to_s]
    end

    def evaluate_value(self_id, ref_cell, src_field, src_field_id, cache = {})
      absolute_value = ref_cell.nil? ? {} : ref_cell.absolute_value
      ref_row = absolute_value[:row]
      value = absolute_value[self_id.to_s]

      if value.nil?
        if ref_row
          case src_field
          when NilClass
            value = Field.missing_msg(src_field_id)
          when Fields::Data
            actual_row = Field.row_by_field(src_field, ref_row)
            att_cell =  actual_row.cell(src_field.custom_field_id) unless actual_row.nil?
            value = att_cell.nil? ? '' : att_cell.to_html
          else
            value = src_field.evaluate_value(ref_row, cache)
          end
        else
          value = nil
        end
      end

      value
    end
  end

  def description
    'Display information from the selected Reference'
  end

  def reference_field
    @reference_field ||= self.screen.fields.select{|f| f.id == reference_field_id }.first
  end

  def reference_field_id
    self.value ||= {}
    self.value[:reference_field_id].to_i
  end

  def source_custom_field
    source_f = source_field
    
    if source_f.is_a?(Fields::ReferenceAttribute)
      source_f.source_custom_field
    else
      source_f.custom_field
    end
  end

  def source_field
    Field.find(source_field_id) if Field.exists?(source_field_id)
  end

  def source_field_id
    self.value ||= {}
    self.value[:source_field_id].to_i
  end

  def reference_custom_field
    reference_field.custom_field if reference_field
  end

  def reference_custom_field_id
    reference_field.custom_field_id if reference_field
  end

  def evaluate_value(row, cache = {})
    Field.cached_value(self[:id], row){
      # actual_row = Field.row_by_field(source_field, row)
      actual_row = row
      Fields::ReferenceAttribute.evaluate_value(self.id, actual_row.cell(reference_custom_field_id), source_field, source_field_id, cache) unless actual_row.nil?
    }
  end

  def evaluate_text(row)
    evaluate_value(row)
  end

  def text(cell_value)
    case source_field
    when NilClass then
      cell_value.to_s
    when Fields::Data then
      source_field.custom_field.text(cell_value)
    else
      source_field.text(cell_value)
    end
  end

  def validate_value(value)
    case source_field
    when Fields::ReferenceAttribute, Fields::CodeCombindedReferenceAttribute
      source_field.validate_value(value)
    when Fields::Data
      source_field.custom_field.validate_value(value)
    end
  end

  def writable?
    true
  end

end