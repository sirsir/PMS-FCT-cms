class Fields::CodeCombindedReferenceAttribute < Field

  class << self

    def evaluate_value(row, field_id, ccr_field, src_field, src_field_id, cache = {})
      actual_row = Field.row_by_field(ccr_field, row)
      ccr_cell = actual_row.cell(ccr_field.custom_field_id) unless actual_row.nil?
      absolute_value = ccr_cell.nil? ? {} : ccr_cell.value
      ref_row_id = absolute_value[:ocr_row_id]
      value = absolute_value[field_id.to_s]

      unless value
        if ref_row_id
          ref_row = Row.find(ref_row_id)
          
          case src_field
          when NilClass
            value = Field.missing_msg(src_field_id)
          when Fields::Data
            if ref_row.screen_id == src_field.screen_id
              actual_row = Field.row_by_field(src_field, ref_row)
              att_cell = actual_row.cell(src_field.custom_field_id) unless actual_row.nil?
              value = att_cell.nil? ? '' : att_cell.to_html
            else
              selected_option_row_ids = absolute_value[:opt_row_ids].collect{|r_id| r_id.to_i if r_id.to_i > 0 }.compact
              unless selected_option_row_ids.empty?
                selected_values = CustomFields::CodeCombindedReference.cell_selecteds(absolute_value)
                selected_values = selected_values.flatten.collect{|item| item[:row_id] }

                model_options = CustomFields::OptionCombindedReference.model_options(ref_row, selected_values.flatten, ccr_field.source_field)

                values = selected_option_row_ids.collect{|r_id| src_field.evaluate_value(model_options[r_id], cache) unless model_options[r_id].nil? }.compact
                value = values.collect{|v| v.to_f }.sum
              end
            end
          else
            value = src_field.evaluate_value(ref_row, cache)
          end
        else
          value = Cell.missing_msg(actual_row.id, ccr_field.custom_field_id)
        end
      end

      value
    end
  end

  def description
    'Display information from the selected Code Combinded Reference'
  end

  def special_values(screen)
    ccr_field = screen.has_field(self.value[:custom_field_id])
    if ccr_field == []
      'Please add field Code Combined Reference before attribute.'
    elsif ccr_field.length == 1
      ocr_field = ccr_field[0].source_field
      ocr_field.screen.fields
    else
      'Cannot add code Code Combined Reference in multi Code Combined Reference screen.'
    end
  end

  def source_field
    Field.find(source_field_id) if Field.exists?(source_field_id)
  end

  def source_field_id
    self.value[:source_field_id].to_i
  end

  def ccr_field
    Field.find(ccr_field_id) if Field.exists?(ccr_field_id)
  end

  def ccr_field_id
    self.value[:field_id].to_i
  end

  def reference_custom_field_id
    ccr_field.custom_field_id if ccr_field
  end

  def evaluate_value(row, cache = {})
    Field.cached_value(self[:id], row){
      Fields::CodeCombindedReferenceAttribute.evaluate_value(row, self[:id], ccr_field, source_field, source_field_id, cache)
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

  def html(cell_value)
    cell_value
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