class Fields::Comparison < Field
  
  class << self
    def text(comparison, true_or_false)
      label_id = comparison[:"#{true_or_false}_label_id"].to_i
      
      (label_id ==0) ? true_or_false.to_s.capitalize : Label.find(label_id).descr
    end
    #   Fields::Comparison.field_comparison(Hash)  -> an_hash
    #
    # field_value = {
    #     :comparison = {
    #         :field_id => '1',
    #         :operator => ==,
    #         :comparer => '2',
    #         :true_label_id => '3',
    #         :false_label_id => '4',
    #       }
    #   }

    def evaluate_syntax(comparison)
      if !comparison.nil?
        operator = comparison[:operator].to_s
        field_id = comparison[:field_id].to_i
        comparer = comparison[:comparer].to_i

        comparer_label = Label.find(comparer)
        #comparer_label = Label.find(comparer)

        case operator
        when '>', '<', '>=', '<=', '==', '!=', '=~', '!~'
          "(#{Field.find(field_id).descr} #{operator} #{comparer_label.descr})?"
        when 'empty?'
          "(#{Field.find(field_id).descr} is null)?"
        when 'and', 'or'
          "(#{Field.find(field_id).descr} #{operator} #{comparer_label.descr})"
        when 'not'
          "#{operator}(#{Field.find(field_id).descr}"
        end
      else
        nil
      end
    end

    def evaluate_text(comparison, row)
      # row has column A, B, C
      # a_value
      # A can be Data, Formula, Accumulation, ...
      field_id = comparison[:field_id].to_i
      operator = comparison[:operator].to_s
      comparer = comparison[:comparer].to_i
      field = Field.find(field_id)
      actual_row = Field.row_by_field(field, row)
      cell = actual_row.cell(field.custom_field_id) unless actual_row.nil?
      
      if cell.nil?
        true_or_false = false
      elsif operator == 'empty?'
        true_or_false = field.custom_field.is_empty?(cell.value)
      else
        # field_value ?
        case field
        when Fields::Data then
          case cell.field
          when CustomFields::Reference,
              CustomFields::CodeCombindedReference,
              CustomFields::OptionCombindedReference,
              CustomFields::ScreenCombindedReference
            field_value = cell.to_text
            comparer = Label.find(comparer).descr
          when CustomFields::RadioButton
            label = CustomFields::RadioButton.cell_label(cell.value)
            field_value = label.is_a?(Label) ? label.descr : label
            comparer = Label.find(comparer).descr
          when CustomFields::NumericField
            field_value = cell.absolute_value
            comparer = Label.find(comparer).descr.to_f
          else
            field_value = cell.absolute_value
          end
        when Fields::DetailInfo then
          #~ ToDo: Get DetailInfo as String
        when Fields::Accumulation, Fields::Formula, Fields::Comparison, Fields::HeaderInfo then
          field_value = field.evaluate_text(row)
        when Fields::ReferenceAttribute, Fields::CodeCombindedReferenceAttribute then
          field_value = field.evaluate_text(row)
          comparer = Label.find(comparer).descr
        else
          #~ ToDo: Raise error
        end

        case field_value
        when String then
            sym = (operator == '=~' or operator == '!~') ? '/' : "'"

            field_value = field_value.gsub("'", "\\\\'")
            comparer = (sym == '/') ? Regexp.escape(comparer) : comparer.gsub("'", "\\\\'")

            eval_text = "'#{field_value}' #{operator} #{sym}#{comparer}#{sym}" + (sym == '/' ? 'i' : '')
        when Array then
          # Currently just for the CheckBox CustomField
          label_ids = field_value.collect{|obj| obj.keys[0] if obj.values[0] }.compact
          label_ids.collect!{|l| l.id } if label_ids.all?{|l| l.is_a?(Label)}
          eval_text = 'label_ids.include?(comparer)'
        when Label then
          eval_text = "#{field_value.id} #{operator} #{comparer}"
        when DateTime, Date, Time then
          eval_text = "#{field_value} #{operator} #{comparer}"
        else
          eval_text = "#{field_value} #{operator} #{comparer}"
        end

        true_or_false = eval(eval_text) unless eval_text =~ /error_message/
      end
      
      text(comparison, true_or_false ? :true : :false)
    end

    def evaluate_value(comparison, row, cache = {})
      # row has column A, B, C
      # a_value 
      # A can be Data, Formula, Accumulation, ...
      field_id = comparison[:field_id].to_i
      operator = comparison[:operator].to_s
      comparer = comparison[:comparer].to_i
      field = Field.find(field_id)
      actual_row = Field.row_by_field(field, row)
      cell = actual_row.cell(field.custom_field_id) unless actual_row.nil?
      cell = field.evaluate_value(row, cache) if field.is_a?(Fields::HeaderInfo) or
        field.is_a?(Fields::Formula) or field.is_a?(Fields::ReferenceAttribute)

      if !cell.nil? or field.is_a?(Fields::Accumulation)
        if operator == 'empty?'
          true_or_false = field.custom_field.is_empty?(cell.value)
        else
          # field_value ?
          case field
          when Fields::Data then
            case cell.field
            when CustomFields::Reference,
                CustomFields::CodeCombindedReference,
                CustomFields::OptionCombindedReference,
                CustomFields::ScreenCombindedReference
              field_value = cell.to_text
            when CustomFields::RadioButton
              label = CustomFields::RadioButton.cell_label(cell.value)
              field_value = label.is_a?(Label) ? label.descr : label
            else
              field_value = cell.absolute_value
            end
          when Fields::DetailInfo then
            #~ ToDo: Get DetailInfo as String
          when Fields::Accumulation, Fields::Comparison then
            field_value = field.evaluate_value(row, cache)
          when Fields::HeaderInfo, Fields::Formula, Fields::ReferenceAttribute then
            field_value = cell
          else
            #~ ToDo: Raise error
          end

          case field_value
          when String then
            sym = (operator == '=~' or operator == '!~') ? '/' : "'"

            field_value = field_value.gsub("'", "\\\\'")
            comparer = Label.find(comparer).descr
            comparer = (sym == '/') ? Regexp.escape(comparer) : comparer.gsub("'", "\\\\'")

            eval_text = "'#{field_value}' #{operator} #{sym}#{comparer}#{sym}" + (sym == '/' ? 'i' : '')
          when Numeric then
            comparer = Label.find(comparer).descr
            eval_text = "#{field_value.to_f} #{operator} #{comparer.to_f}"
          when Array then
            # Currently just for the CheckBox CustomField
            label_ids = field_value.collect{|obj| obj.keys[0] if obj.values[0] }.compact
            label_ids.collect!{|l| l.id } if label_ids.all?{|l| l.is_a?(Label)}
            eval_text = 'label_ids.include?(comparer)'
          when Label then
            eval_text = "#{field_value.id} #{operator} #{comparer}"
          when DateTime, Date, Time then
            eval_text = "#{field_value} #{operator} #{comparer}"
          when NilClass
            eval_text = 'false'
          else
            eval_text = "#{field_value} #{operator} #{comparer}"
          end

          true_or_false = eval(eval_text) unless eval_text =~ /error_message/
        end

        true_or_false ? 1 : 0
      else
        true_or_false = 0
      end
    end
    
  end

  def description
    'Display compared information'
  end
  
  def comparison
    self[:value][:comparison]
  end
  
  def field_id
    self[:value][:comparison]
  end
  
  def comparison
    self[:value][:comparison]
  end

  def evaluate_value(row, cache = {})
    Field.cached_value(self[:id], row){
      Fields::Comparison.evaluate_value(comparison, row, cache)
    }
  end

  def evaluate_text(row)
    Fields::Comparison.evaluate_text(comparison, row)
  end

  #  exp_1 = {:fnc => 'DIV', :var_1 => 'x', :var_2 => 'y'}
  #  f = Fields::Formula.new(:value => {:formula=>exp_1})
  def evaluate_syntax
    Fields::Comparison.evaluate_syntax(self.comparison)
  end
  
  def text(cell_value)
    Fields::Comparison.text(comparison, cell_value.to_i == 0 ? :false : :true)
  end

end
