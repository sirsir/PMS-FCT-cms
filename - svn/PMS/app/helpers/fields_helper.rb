module FieldsHelper

  def fields_comparison_path(options)
    field_path(options)
  end

  def fields_accumulation_path(options)
    field_path(options)
  end

  def fields_formula_path(options)
    field_path(options)
  end

  def fields_data_path(options)
    field_path(options)
  end

  def fields_detail_info_path(options)
    field_path(options)
  end

  def fields_header_info_path(options)
    field_path(options)
  end

  def fields_reference_attribute_path(options)
    field_path(options)
  end

  def fields_code_combinded_reference_attribute_path(options)
    field_path(options)
  end

  def fields_grouping_path(options)
    field_path(options)
  end

  def update_ref_att_javascript(field, options = {})
    defaults = {
      :value => 'this.value'
    }
    options = defaults.merge(options)

    ref_attr_fields = field.reference_attribute_fields || []

    display_in_form_fields = ref_attr_fields.select{|f|
      case f
      when Fields::ReferenceAttribute
        reference_field_method = :reference_field
      when Fields::CodeCombindedReferenceAttribute
        reference_field_method = :ccr_field
      end

      display_in_form = !field.read_only? &&
        reference_field_method &&
        f.send(reference_field_method).display_in_form?

      f.display_in_form? || display_in_form
    }

    display_in_form_fields.collect do |f|
      i = display_in_form_fields.index(f)

      javascript_var = "JAVASCRIPT_VAR_VALUE_#{i.to_s.rjust(2, '0')}"

      reference_att_url = url_for(:controller => 'rows',
        :action => 'reference_attribute',
        :id => 0,
        :field_id => f.id,
        :source_field_id => f.source_field.id,
        :row_id => javascript_var
      )

      <<JAVASCRIPT
fncAjaxUpdaterWithReplacement('ref_att_#{f.id}','#{reference_att_url}', ['#{javascript_var}', #{options[:value]}]);
JAVASCRIPT
    end.join
  end

  def js_reset_ccr_ref_attrib_fields(field, input_name)
    ccr_attribute_fields = field.wildcard? ? [] : field.code_combined_reference_attribute_fields

    div_ids = ccr_attribute_fields.collect do |f|
      div_id = sanitize_to_id("#{input_name}[#{f.id.to_s}]")

       "\"#{div_id}\""
    end

    <<JAVASCRIPT
fncClearTextBox([#{div_ids.join(', ')}]);
JAVASCRIPT
  end

  def js_update_field_flag_value(flag_id)
        <<JAVASCRIPT
    $('#{flag_id}').value = this.value;
    $('#{flag_id}').click();
JAVASCRIPT
  end
  
  def js_trigger_tag(id, value, options = {})
    properties = options.collect do |k,v|
      <<PROP
#{k}="#{v}"
PROP
    end

    <<HTML_TAG
<input type="button" class="js_trigger" id="#{id}" value="#{value}" #{properties.join} />
HTML_TAG
  end

  def js_caller_tag(onclick, options = {})
    clicked = 'clicked=true' if options[:clicked]
    style = ''
    style << 'background-Color: lightgreen;' if options[:clicked]
    <<HTML_TAG
<input type="button" class="js_caller" value=">>" style="#{style}" #{clicked} onclick="#{onclick};this.style.backgroundColor='lightgreen';"/>
HTML_TAG
  end
end
