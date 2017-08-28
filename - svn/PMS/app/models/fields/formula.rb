class Fields::Formula < Field

  class << self

    #   Fields::Formula.field_formula(Hash)  -> an_hash
    #
    # field_value = {
    #     :data_type = 'number'
    #     :formula = {
    #         :fnc => 'SUB',
    #         :var_1 => {
    #             :fnc => 'CNS',
    #             :var_1 => '100'
    #           },
    #         :var_2 => {
    #             :fnc => 'VAR',
    #             :var_1 => '99'
    #           }
    #       }
    #   }
    # Get the value for the :formula key
    #   CustomFields::Formula.field_formula(field_value) #=>
    #                                                # {
    #                                                #   :data_type = "number"
    #                                                #   :fnc => "SUB",
    #                                                #   :var_1 => {
    #                                                #       :fnc => "CNS",
    #                                                #       :var_1 => "100"
    #                                                #     },
    #                                                #   :var_2 => {
    #                                                #       :fnc => "VAR",
    #                                                #       :var_1 => "99"
    #                                                #     }
    #                                                # }
    #   CustomFields::Formula.field_formula({})          #=> {}
    #   CustomFields::Formula.field_formula(nil)         #=> {}
    def field_formula(field_value)
      field_value ||= {}

      field_value[:relate_to].to_i
    end

    # Sample:
    #   fnc = (a*(x - y)) / (b*(x + y))
    #   a = 3
    #   b = 4
    #   x = 10
    #   y = 2
    #
    #  exp_6 = {:fnc => 'CNS', :var_1 => '3'} # a
    #  exp_7 = {:fnc => 'CNS', :var_1 => '4'} # b
    #  exp_8 = {:fnc => 'VAR', :var_1 => '98'} # x
    #  exp_9 = {:fnc => 'VAR', :var_1 => '99'} # y
    #  exp_10 = {:fnc => 'VAR', :var_1 => '98'} # x
    #  exp_11 = {:fnc => 'VAR', :var_1 => '99'} # y
    #  exp_5 = {:fnc => 'ADD', :var_1 => exp_10, :var_2 => exp_11}
    #  exp_4 = {:fnc => 'SUB', :var_1 => exp_8, :var_2 => exp_9}
    #  exp_3 = {:fnc => 'MUL', :var_1 => exp_7, :var_2 => exp_5}
    #  exp_2 = {:fnc => 'MUL', :var_1 => exp_6, :var_2 => exp_4}
    #  exp_1 = {:fnc => 'DIV', :var_1 => exp_2, :var_2 => exp_3}
    #
    # :formula = {
    #   :fnc => 'DIV',
    #   :var_1 => {
    #     :fnc => 'MUL',
    #     :var_1 => {
    #         :fnc => 'CNS',
    #         :var_1 => '3'
    #       },
    #     :var_2 => {
    #         :fnc => 'SUB',
    #         :var_1 => {
    #             :fnc => 'VAR',
    #             :var_1 => '98'
    #           },
    #         :var_2 => {
    #             :fnc => 'VAR',
    #             :var_1 => '99'
    #           }
    #       }
    #     },
    #   :var_2 => {
    #       :fnc => 'MUL',
    #       :var_1 => {
    #           :fnc => 'CNS',
    #           :var_1 => '4'
    #         },
    #       :var_2 => {
    #           :fnc => 'ADD',
    #           :var_1 => {
    #             :fnc => 'VAR',
    #             :var_1 => '98'
    #           },
    #         :var_2 => {
    #             :fnc => 'VAR',
    #             :var_1 => '99'
    #           }
    #         }
    #     }
    #   }
    #
    #  f = Fields::Formula.new(:value => {:formula=>exp_1})
    #  f.evaluate_value(nil) #=> 0.5
    #
    #   fnc = DatePart(p, x)
    #   p = MNT : Month
    #   x = '2010/01/01'
    #
    #   :formula = {
    #      :fnc => 'DAT',
    #      :var_1 => 'MNT'
    #      :var_2 => {
    #         :fnc => 'VAR',
    #         :var_1 => '99'
    #       }
    #     }
    #
    def evaluate_value(exp, row, cache = {}, options = {})
      defaults = {
        :data_type => :number,
        :row_cell_value => {}
      }
      options = defaults.merge(options)
      data_type = options[:data_type]

      cache[row.id] ||= {}
      result = cache[row.id][exp.inspect]

      unless exp.nil? || cache[row.id].has_key?(exp.inspect)
        operation = operators[exp[:fnc]]
        cast_method = (data_type == :text) ? 'to_s' : 'to_f'
        
        var_1 = (exp[:var_1].nil? ? 0 : evaluate_value(exp[:var_1], row, cache, options)).send(cast_method)
        var_2 = (exp[:var_2].nil? ? 0 : evaluate_value(exp[:var_2], row, cache, options)).send(cast_method)

        unless operation.nil? || data_type == :text
          case operation
          when  '+', '-', '*', '/'
            if var_2 == 0 and operation =='/'
              result = 0.to_f
            else
              result = eval("#{var_1} #{operation} #{var_2}")
            end
          when 'and', 'or'
            result = eval("#{!var_1.zero?} #{operation} #{!var_2.zero?}")? 1 : 0
          when '!'
            result = var_1.zero? ? 1 : 0
          when 'FLR'
            result = CustomFields::NumericField.floor_to(var_1, var_2)
          when 'CEL'
            result = CustomFields::NumericField.ceil_to(var_1, var_2)
          end
        else
          case exp[:fnc]
          when 'DAT'
            #~ ToDo: Evaluate Date function
            # Remark: Business Year start on 1st April (9999/04/01)
            # Input : 2010/10/01
            # MNT : { :value =>201001, :text => "October, 2010"}
            # QRT : { :value =>20103, :text => "3rd Quarter, 2010"}
            # HYR : { :value =>20102, :text => "2st Half, 2010"}
            # YER : { :value =>2010, :text => "2010"}
            field = Field.find(exp[:var_2].to_i)
            actual_row = Field.row_by_field(field, row)
            cell = actual_row.cell(field.custom_field_id) unless actual_row.nil?
            
            unless cell.nil?
              time = cell.absolute_value.to_datetime

              if ['QRT', 'HYR'].include?(exp[:var_1])
                first_month = Date.null_date.strftime('%m').to_i
                test_month = time.strftime('%m').to_i
                test_month += 12 if test_month < first_month
              end

              if exp[:var_1] == 'MNT'
                result = time.strftime('%m').to_i
              elsif exp[:var_1] == 'YER'
                result = time.strftime('%Y').to_i
              elsif exp[:var_1] == 'QRT'
                result = ((test_month - first_month) / 3) + 1
              elsif exp[:var_1] == 'HYR'
                result = ((test_month - first_month) / 6) + 1
              end
            end
          when 'CCT'
            result = [var_1, var_2].join
          when 'CNS'
            result = exp[:var_1].send(cast_method)
          when 'VAR'
            field = case row
            when ReportRequestRow
              report_request_cols = [options[:report_request_cols]].flatten.compact
              row_report_request_cols = row.report_request.report.cell_fields_reports.collect do |cfr|
                cfr.report_request_cols.select{|rrc| rrc.report_request_id == row.report_request_id } if "#{cfr.field_id}|#{cfr.reference_screen_index}" == exp[:var_1]
              end.compact.flatten
              
              report_request_col = (report_request_cols & row_report_request_cols).first

              report_request_col ||= report_request_cols.first
            else
              Field.find(exp[:var_1].to_i)
            end
            
            #~ Field Type
            result = case field
            when Fields::Accumulation, Fields::Formula, Fields::HeaderInfo,
                Fields::ReferenceAttribute, Fields::Comparison, Fields::CodeCombindedReferenceAttribute
              actual_row = Field.row_by_field(field, row)
              eval_value = field.evaluate_value(actual_row, cache) unless actual_row.nil?
              eval_value = eval_value.to_s.delete(',') if cast_method == 'to_f'
              eval_value.send(cast_method)
            when ReportRequestCols::FieldSrc, ReportRequestCols::FormulaSrc
              rows = row.leaf_report_request_rows
              cell_values = rows.collect do |r|
                options[:row_cell_value][r.id] ||= {}
                
                case field
                when ReportRequestCols::FieldSrc
                  options[:row_cell_value][r.id][field.id] ||= r.cell(field.id).value if r.cell(field.id)
                when ReportRequestCols::FormulaSrc
                  options[:row_cell_value][r.id][field.id][exp[:var_1]]
                end                
              end.compact.flatten

              ReportRequestCell.evaluate(cell_values)
            else
              actual_row = row_by_field(field, row)
              cell = actual_row.cell(field.custom_field_id)
              unless cell.nil?
                cf = cell.field
                case cf
                when CustomFields::RadioButton
                  cf.other_value(cell.value)
                else
                  cell.absolute_value.send(cast_method) 
                end
              end
            end
          end
        end

        cache[row.id][exp.inspect] = result
      end
      
      result || 0
    end

    # exp_1 = {:fnc => "DIV", :var_1 => "x", :var_2 => "y"}
    # Fields::Formula.evaluate_syntax(exp_1) #=> "(x / y)"
    def evaluate_syntax(exp, options = {})
      defaults = {
        :recursive => false,
        :for_evaluate_value => false
      }
      options = defaults.merge(options)

      result = ''

      if !exp.nil?
        operation = operators[exp[:fnc]]

        if !operation.nil?
          var_1 = evaluate_syntax(exp[:var_1], options)
          var_2 = evaluate_syntax(exp[:var_2], options)
          
          case operation
          when '+', '-', '*', '/'
            result = "(#{var_1} #{operation} #{var_2})"
          when 'and', 'or'
            if options[:for_evaluate_value]
              result = "((!#{var_1}.zero? #{operation} !#{var_2}.zero?)? 1 : 0)"
            else
              result = "(#{var_1} #{operation} #{var_2})"
            end
          when '!'
            if options[:for_evaluate_value]
              # var_1.zero? ? 1 : 0
              result = "(#{var_1}.zero? ? 1 : 0)"
            else
              result = "!(#{var_1})"
            end
          when 'FLR', 'CEL'
            result = "#{operation}(#{var_1},#{var_2})"
          end
        elsif exp[:fnc]== 'DAT' or exp[:fnc]== 'CNS' or exp[:fnc]== 'VAR' or exp[:fnc]== 'FLO'
          case exp[:fnc]
          when 'DAT'
            descr = Field.find(exp[:var_2].to_i).custom_field_label_descr
            date_fmt = date_formats[exp[:var_1]]
            
            result ="DATE(#{date_fmt}, #{descr})"
          when 'CNS'
            result = exp[:var_1]
          when 'VAR'
            f = Field.find(exp[:var_1].to_i)
            
            case f
            when Fields::HeaderInfo
              result = f.full_descr
            when Fields::Formula
              result = options[:recursive] ? f.evaluate_syntax(options) : f.full_descr
            else
              result = f.full_descr
            end
          end
        else
          result = exp[:fnc]
        end
      end
      result
    end

    # Fields::Formula.explain(exp_1, row) #=> "(100 / 0.7) [142.857] * 1.05 [150.0]"
    def explain(exp, row, cache = {}, options = {})
      result = ''

      if !exp.nil?
        operation = operators[exp[:fnc]]

        if !operation.nil?
          var_1 = explain(exp[:var_1], row, cache)
          var_2 = explain(exp[:var_2], row, cache)

          case operation
          when '+', '-', '*', '/', 'and', 'or'
            result = "(#{var_1} #{operation} #{var_2})"
          when '!'
            result = "!(#{var_1})"
          when 'FLR','CEL'
            result = "#{operation}(#{var_1},#{var_2})"
          end
        elsif exp[:fnc]== 'DAT' or exp[:fnc]== 'CNS' or exp[:fnc]== 'VAR' or exp[:fnc]== 'FLO'
          case exp[:fnc]
          when 'DAT'
            descr = Field.find(exp[:var_2].to_i).custom_field_label_descr
            date_fmt = date_formats[exp[:var_1]]

            result ="DATE(#{date_fmt}, #{descr})"
          when 'CNS'
            result = exp[:var_1]
          when 'VAR'
            f = Field.find(exp[:var_1].to_i)
            if f.is_a?(Fields::HeaderInfo)
              result = f.full_descr
            else
              result = f.full_descr
            end
          end
        else
          result = exp[:fnc]
        end
      end
      "#{result}[#{evaluate_value(exp, row, cache, options)}]"
    end

    def depth(exp)
      if (!exp[:var_1].nil? and exp[:var_1].is_a?(Hash)) and (!exp[:var_2].nil? and exp[:var_2].is_a?(Hash))
        a = [depth(exp[:var_1]),depth(exp[:var_2])]
        1 + a.max
      elsif (!exp[:var_1].nil? and exp[:var_1].is_a?(Hash))
        depth(exp[:var_1])+1
      elsif (!exp[:var_2].nil? and exp[:var_2].is_a?(Hash))
        depth(exp[:var_2])+1
      else
        0
      end
    end

    def extract_keys(exp)
      ar_result = []
      exp.each do |k, v|
        extract_key(v, [k.to_s], ar_result)
      end
      ar_result
    end
    
    def extract_key (exp, ar_path, ar_result)
      exp.each do |k, v|
        if v.is_a?(Hash)
          local_ar_path = ar_path.clone
          local_ar_path << k.to_s 
          extract_key(v, local_ar_path, ar_result)
        else
          local_ar_path = ar_path.clone
          local_ar_path << k.to_s if !v.nil?
          ar_result << local_ar_path
        end
      end
    end 
    
    def hidden_field_name(exp)
      ar_result = extract_keys(exp)
      ar_name = []
      ar_result.each do |row|
        b = ''
        row.each do |column|
          b = "#{b}[#{column.to_s}]"
        end
        ar_name << "field[value][formula]#{b}"
      end
      ar_name
    end
    
    def hidden_field_value(exp)
      ar_result = extract_keys(exp)
      ar_value = []
      ar_result.each do |row|
        b = ''
        row.each do |column|
          b = "#{b}[:#{column.to_s}]"
        end
        ar_value << eval("exp#{b}")
      end
      ar_value
    end

    def name2id(name)
      while name.indexOf('][') >=0
        name = name.gsub('][', '_')
      end
      return name.gsub('[', '_').gsub(']', '')
    end
    
    private
    
    def operators
      @@operator ||= {
        'ADD' => '+',
        'SUB' => '-',
        'MUL' => '*',
        'DIV' => '/',
        'FLR' => 'FLR',
        'CEL' => 'CEL',
        'AND' => 'and',
        'OR' => 'or',
        'NOT' => '!',
        'CCT' => '+'
      }
    end
    
    def date_formats
      @@date_formats ||= {
        'MNT' => 'MNT',
        'YER' => 'YEAR',
        'QRT' => 'QUATER',
        'HYR' => 'HALF-YEAR'
      }
    end
  end

  def description
    'Display calculated information from Data fields (ADD, DIF, MUL, DIV, etc.)'
  end

  def formula
    self[:value][:formula]
  end

  def evaluate_value(row, cache = {})
    Field.cached_value(self[:id], row){
      Fields::Formula.evaluate_value(self.formula, row, cache, {:data_type => self.data_type})
    }
  end

#  def evaluate_value(row, cache = {})
#    row.field_cache[self[:id]] ||= Field.cached_value(self[:id], row) do
#      cast_method = (self.data_type == :text) ? 'to_s' : 'to_f'
#      syntax = ''
#      begin
#        syntax = evaluate_syntax({ :include_variable => true, :recursive => true, :for_evaluate_value => true })
#
#        eval syntax
#      rescue Exception => ex
#        message = ['= '*60, 'Invalide formula syntax evaluation', syntax, ex.message, '= '*60].join("\n")
#        Rails.logger.error(message)
#        puts message
#      end.send(cast_method)
#    end
#  end

  def explain(row, cache = {})
    Fields::Formula.explain(self.formula, row, cache)
  end

  #  exp_1 = {:fnc => 'DIV', :var_1 => 'x', :var_2 => 'y'}
  #  f = Fields::Formula.new(:value => {:formula=>exp_1})
  def evaluate_syntax(options = {})
    defaults = {
      :recursive => false,
      :include_variable => false,
      :for_evaluate_value => false
    }
    options = defaults.merge(options)

    @evaluate_syntax ||= {}
    @evaluate_syntax[options.inspect] ||= begin
      include_variable = options.delete(:include_variable)
      
      syntax = Fields::Formula.evaluate_syntax(self.formula, options)
      
      if include_variable
        variable_list = []

        fields = self.screen.fields.sort_by{|f| [f.full_descr.size, f.full_descr] }.reverse

        fields.each do |f|
          full_descr_exp = /#{Regexp.escape(f.full_descr)}/
          if syntax =~ full_descr_exp
            var_name = "var_field_#{f.id}"
            variable_list << <<RUBY_CODE
#{var_name} = Field.find(#{f.id}).evaluate_value(row, cache)
#{var_name} = #{var_name}.to_s.delete(',') if cast_method == 'to_f'
#{var_name} = #{var_name}.to_f
RUBY_CODE

            syntax.gsub!(full_descr_exp, var_name)
          end unless f.full_descr.empty?
        end
        
        {
          /FLR\(/ => 'CustomFields::NumericField.floor_to(',
          /CEL\(/ => 'CustomFields::NumericField.ceil_to(',
          / and / => ' && ',
          / or / => ' || '
        }.each do |k, v|
          syntax.gsub!(k, v)
        end
        
        syntax = <<RUBY_CODE
#{variable_list.join("\n")}

#{syntax}
RUBY_CODE
      end
      
      syntax
    end
  end
  
  def text(cell_value)
    if cell_value.to_s.empty?
      cell_value.to_s
    else
      case format
      when :percentage then
        number_to_percentage(cell_value, option)
      when :human_size then
        number_to_human_size(cell_value, option)
      else
        number_with_precision(cell_value, option)
      end
    end
  end

  def data_type
    self[:value] ||= {}
    self[:value][:data_type] ||= :number
    self[:value][:data_type].to_sym
  end

  def format
    self[:value] ||= {}
    self[:value][:format] ||= :number
    self[:value][:format].to_sym
  end

  def option
    options = {}
    self[:value] ||= {}
    self[:value][:option] ||= {}
    options[:delimiter] =  self[:value][:option][:delimiter] ||= (format == :number || :currency) ? ',' : ''
    options[:separator] =  self[:value][:option][:separator] ||= '.'
    options[:precision] =  self[:value][:option][:precision] ||= case format
    when :number, :currency then 2
    when :percentage then 3
    when :human_size then 1
    end
    options[:precision] = options[:precision].to_i

    unless(format != :currency)
      options[:unit] = self[:value][:option][:unit] ||= :USD
      options[:unit] = options[:unit].to_sym
    end

    options
  end

  # Validated that the required values are present
  def validate_mandatory
    errors.add('Formula', 'is incomplete') if self.evaluate_syntax =~ /\[(fnc|var1)\]/
  end
  
  private

end
