# Stored value structure
#
# *CustomField*
#   custom_field.value = nil
#
# *Field*
#   field.value = {
#       :relate_to => 1,
#       :related_from => 2,
#       :field_id => 3
#     }
#
# *Cell*
#   cell.value = {
#       :scr_row_id => 1,
#       :options => {
#           '0' => { :row_ids => [11] },
#           '1' => { :row_ids => [21] },                #~ Sample case when row_id=21 is 3 sub groups
#           '2' => { :group	=> 3 },                     #~ Redirect to the group options
#           '3' => { :row_ids => [41,42] },
#           '4' => { :row_ids => [51,52,53] },
#           '5' => { :row_ids => [61] },
#           '6' => { :row_ids => [71] }
#         },
#       :groups => {
#           '0' => {                                    #~ Index 0 (sub group-1)
#               :options => {
#                   '0' => { :row_ids => [3111] },
#                   '1' => { :row_ids => [3121] },
#                   '2' => { :row_ids => [3131,3132,3133] }
#                 },
#               }
#           '1' => {                                    #~ Index 1 (sub group-2)
#               :options => {
#                   '0' => { :row_ids => [3211] },
#                   '1' => { :row_ids => [3221] },
#                   '2' => { :row_ids => [3231,3232,3233] }
#               }
#             },
#           '2' => {                                    #~ Index 2 (sub group-3)
#               :options => {
#                   '0' => { :row_ids => [3311] },
#                   '1' => { :row_ids => [3321] },
#                   '2' => { :row_ids => [3331,3332,3333] }
#               }
#             }
#         }
#     }
#
# *Note*: The options has to be a hash because, when creating the input control,
# only one array can be specified in the name. Double array will be impossible.
#
#   <input name="cell[value][options][][row_ids][]" />
#
# There so, the first level array as to me managed as a hash, with the index as
# the key
#
#   <input name="cell[value][options][0][row_ids][]" />
class CustomFields::OptionCombindedReference < CustomField

  class << self
    def row_in_use?(row_id, ocr_cells, all = false)
      row_in_use_by = []

      ocr_cells.each do |ocr_c|
        options = cell_options(ocr_c[:value])

        next if options.empty?

        row_ids = options.flatten.collect{|o| o[:row_ids] }.flatten.uniq

        row_in_use_by << ocr_c.row if row_ids.include?(row_id)

        break unless all || row_in_use_by.empty?
      end

      all ? row_in_use_by : row_in_use_by.first
    end

    #   CustomFields::OCR.field_relate_to(Hash)  -> int
    #
    # Get the value for the :relate_to key
    #   CustomFields::OCR.field_relate_to({:relate_to => 1}) #=> 1
    #   CustomFields::OCR.field_relate_to({})                #=> 0
    #   CustomFields::OCR.field_relate_to(nil)               #=> 0
    def field_relate_to(field_value)
      field_value ||= {}

      field_value[:relate_to].to_i
    end
    
    #   CustomFields::OCR.field_related_from(Hash) -> int
    #
    # Get the value for the :related_from key
    #   CustomFields::OCR.field_related_from({:related_from => 1}) #=> 1
    #   CustomFields::OCR.field_related_from({})                   #=> 0
    #   CustomFields::OCR.field_related_from(nil)                  #=> 0
    def field_related_from(field_value)
      field_value ||= {}

      field_value[:related_from].to_i
    end
    
    #   CustomFields::OCR.field_scr_field_id(Hash) -> int
    #
    # Get the value for the :field_id key
    #   CustomFields::OCR.field_scr_field_id({:field_id => 1}) #=> 1
    #   CustomFields::OCR.field_scr_field_id({})               #=> 0
    #   CustomFields::OCR.field_scr_field_id(nil)              #=> 0
    def field_scr_field_id(field_value)
      field_value ||= {}

      field_value[:field_id].to_i
    end
    
    #   CustomFields::OCR.cell_scr_row_id(Hash) -> int
    #
    # Get the value for the :scr_row_id key
    #   CustomFields::OCR.cell_scr_row_id({:scr_row_id => 1}) #=> 1
    #   CustomFields::OCR.cell_scr_row_id({})                 #=> 0
    #   CustomFields::OCR.cell_scr_row_id(nil)                #=> 0
    def cell_scr_row_id(cell_value)
      cell_value = cell_value.nil? ? cell_value : cell_value == '' ? nil : cell_value
      cell_value ||= {}

      cell_value[:scr_row_id].to_i
    end

    #   CustomFields::OCR.cell_options(Hash) -> an_array
    #
    # Get the value for the :options key, all id values will be integer
    #   cell_value = {
    #       :options => {
    #           '0' => { :row_ids => [11] },
    #           '1' => { :row_ids => [21] },
    #           '2' => { :group	=> 2 },
    #           '3' => { :row_ids => [41,42] }
    #         },
    #       :groups => {
    #           '0' => {
    #               :options => {
    #                   '0' => { :row_ids => [3111] },
    #                   '1' => { :row_ids => [3121] }
    #                 }
    #             },
    #           '1' => {
    #               :options => {
    #                   '0' => { :row_ids => [3211] },
    #                   '1' => { :row_ids => [3221] }
    #                 }
    #             }
    #         }
    #     }
    #   CustomFields::OCR.cell_options(cell_value)  #=> [
    #                                               #     {:row_ids => [11]},
    #                                               #     {:row_ids => [21]},
    #                                               #     [
    #                                               #       [{:row_ids => [3111]}, {:row_ids => [3121]}],
    #                                               #       [{:row_ids => [3211]}, {:row_ids => [3221]}]
    #                                               #     ],
    #                                               #     {:row_ids => [41,42]}
    #                                               #   ]
    #   CustomFields::OCR.cell_options(cell_value,flase)  #=> [
    #                                               #     {:row_ids => [11]},
    #                                               #     {:row_ids => [21]},
    #                                               #     {:group => 2},
    #                                               #     {:row_ids => [41,42]}
    #                                               #   ]
    #   CustomFields::OCR.cell_options({})          #=> []
    #   CustomFields::OCR.cell_options(nil)         #=> []
    def cell_options(cell_value, include_group=true)
      cell_value = nil if cell_value.to_s.empty?
      cell_value ||= {}
      cell_value[:options] ||= {}
      indexes = cell_value[:options].keys.collect{|k| k.to_i }.sort

      indexes.collect do |i|
        v = cell_value[:options][i.to_s]
        
        if v.has_key?(:group)

          cell_value[:groups] ||= {}

          include_group ? (0..v[:group].to_i-1).collect{|g| cell_options(cell_value[:groups][g.to_s])} : v
        else
          v[:row_ids] = v[:row_ids].is_a?(Array) ? v[:row_ids].collect!{|r_id| r_id.to_i if r_id.to_i > 0} : [v[:row_ids].to_i].collect!{|r_id| r_id.to_i if r_id.to_i > 0}
          v[:row_ids].compact!

          v
        end
      end.compact
    end

    #   CustomFields::OCR.cell_group_options({})          #=> []
    #   CustomFields::OCR.cell_group_options(nil)         #=> []
    def cell_groups(cell_value)
      cell_value = nil if cell_value.to_s.empty?
      cell_value ||= {}
      cell_value[:groups] ||= {}
      indexes = cell_value[:groups].keys.collect{|k| k.to_i }.sort

      indexes.collect do |i|
        options = cell_value[:groups][i.to_s][:options]
        options.collect do |option|
          option.collect do |o|
            if o.is_a?(HashWithIndifferentAccess) then
              o[:row_ids].collect!{|r_id| r_id.to_i if r_id.to_i > 0}
              o
            end
          end
        end
        options
      end.compact
    end
    
    #   CustomFields::OCR.cell_ocr_patterns(custom_field, cell_value) -> an_array
    #  Get all possible pattern the match OCR setting
    def cell_ocr_patterns(custom_field, cell_value)
      ocr_patterns = []

      cell_value = cell_value.value if cell_value.is_a?(Cell)
      ocr_code = custom_field.absolute_value(cell_value, :include_delimiter => true).join
      ocr_codes = []

      all_ocr_codes = ocr_code.split(':').last.gsub(/[\(\)]/, '').split('-')
      all_ocr_codes.each{|c| ocr_codes << c if ocr_codes.size - ocr_codes.uniq.size < 5 }

      number_of_codes = 5
      
      ocr_codes.first(number_of_codes).each do |c|
        codes = c.split('/')

        if ocr_patterns.empty?
          ocr_patterns = codes.collect{|c| [c] }
        else
          ocr_patterns = ocr_patterns.cartprod(codes)
        end
      end

      ocr_patterns.collect{|pattern| pattern.join('-') }
    end

    def allow_removing_used_options?
      false
    end

    #   CustomFields::OCR.related_model_rows(ocr_row, ocr_field) -> collection of row
    def related_model_rows(ocr_row, selected_options, ocr_field)
      ocr_cell = ocr_row.cell(ocr_field.custom_field_id)
      scr_row =  Row.find(CustomFields::CodeCombindedReference.cell_scr_row_id(ocr_cell.value))
      related_model_field = ocr_field.related_model_field
      model_rows = []
      
      unless related_model_field.nil?
        regexp = ocr_cell.custom_field.regexp({}, selected_options.size, selected_options)

        vm = VirtualMemory::load(:ccr_lookup_relations, ApplicationController.current_user.id)
        cell_ids = vm.delete(:cell_ids)
        if cell_ids
          cells = Cell.find(cell_ids)
        else
          main_model_field = ocr_field.main_model_field
          cells = CustomFields::CodeCombindedReference.code_combined_reference_values(scr_row.id, main_model_field)
          
          cell_ids = cells.collect{|c| c.id}
          vm[:cell_ids] = cell_ids

          VirtualMemory::store(:ccr_lookup_relations, ApplicationController.current_user.id, vm)
        end

        model_row_ids = cells.collect do |c|
          value_option = CustomFields::CodeCombindedReference.cell_selecteds(c.value)
          match_selected_options = value_option.flatten.collect{|v| v[:row_id].to_i > 0 ? v[:row_id] : '*' }
          test_text_to_search = match_selected_options.join('-')
          c.row_id.to_i if !regexp.match(test_text_to_search).nil?
        end.compact
      
        unless model_row_ids.empty?
          ccr_rows = Row.find(:all, :conditions => ['id in (?)', model_row_ids])
          related_model_row_ids = ccr_rows.collect do |r|
            related_model_cell = r.cell(related_model_field.custom_field_id)
            CustomFields::CodeCombindedReference.cell_ocr_row_id(related_model_cell.value) if related_model_cell
          end
          model_rows = Row.find(:all, :conditions=>['id in (?)', related_model_row_ids.flatten().uniq])
        end
      end

      model_rows
    end

    #   CustomFields::OCR.model_options(ocr_row, ocr_field, ocr_field) -> hash
    # {:102 =>row_102,
    #  :103 =>row_103
    # }
    def model_options(ocr_row, selected_options, ocr_field)
      result_model_options = {}
      ocr_cell = ocr_row.cell(ocr_field.custom_field_id)  
      scr_row =  Row.find(CustomFields::CodeCombindedReference.cell_scr_row_id(ocr_cell.value))
      length = scr_row.screen_combined_screens.size

      regexp = ocr_cell.custom_field.regexp({}, length, selected_options)
      
      vm = VirtualMemory::load(:ccr_lookup_options, ApplicationController.current_user.id)
      cell_ids = vm.delete(:cell_ids)
      if cell_ids
        cells = Cell.find(cell_ids)
      else
        model_option_field = ocr_field.model_option_field
        cells = (model_option_field.nil?) ? [] : CustomFields::CodeCombindedReference.code_combined_reference_values(scr_row.id, model_option_field)

        cell_ids = cells.collect{|c| c.id}
        vm[:cell_ids] = cell_ids

        VirtualMemory::store(:ccr_lookup_options, ApplicationController.current_user.id, vm)
      end
      
      cells.collect do |c|
        radio_opt_value = CustomFields::CodeCombindedReference.cell_opt_row_ids(c.value).flatten.compact.first
        next if radio_opt_value.nil?

        value_option = c.value[:selecteds] 
        match_selected_options = value_option.collect{|v| v[:row_id].to_i > 0 ? v[:row_id] : '*' }
        test_text_to_search = match_selected_options.join('-')

        result_model_options[radio_opt_value] = Row.find(c.row_id.to_i) unless regexp.match(test_text_to_search).nil?
       end.compact
     result_model_options || {}
    end

    #   cell.value = {
    #       :scr_row_id => 1,
    #       :options => {
    #           '0' => { :row_ids => [11] },
    #           '1' => { :row_ids => [21] },                #~ Sample case when row_id=21 is 3 sub groups
    #           '2' => { :group	=> 3 },                     #~ Redirect to the group options
    #           '3' => { :row_ids => [41,42] }
    #         },
    #       :groups => {
    #           '0' => {                                    #~ Index 0 (sub group-1)
    #               :options => {
    #                   '0' => { :row_ids => [3111] },
    #                   '1' => { :row_ids => [3121] },
    #                   '2' => { :row_ids => [3131,3132,3133] }
    #                 },
    #               }
    #           '1' => {                                    #~ Index 1 (sub group-2)
    #               :options => {
    #                   '0' => { :row_ids => [3211] },
    #                   '1' => { :row_ids => [3221] },
    #                   '2' => { :row_ids => [3231,3232,3233] }
    #               }
    #             },
    #           '2' => {                                    #~ Index 2 (sub group-3)
    #               :options => {
    #                   '0' => { :row_ids => [3311] },
    #                   '1' => { :row_ids => [3321] },
    #                   '2' => { :row_ids => [3331,3332,3333] }
    #               }
    #             }
    #         }
    #     }
    #   model_serie_row   #=> "SSEL"
    #   model_serie_spec  #=> "C-2-20/30/60/100/150/200I-300/400A-NP/PN-0/2/3/5-1/2"
    #   master_data_rows  #=>  NUMBER_OF_AXIS_FOR_CONNECTION => '6/1/2/3/4/5'
    #                          POWER_VOLTAGE => '0/1/2/3'
    #                          I_O_TYPE => 'CC/PR/NP/N/DV/PN'
    #                          ENCODER_TYPE => 'A/I'
    #                          MODEL_TYPE => 'K/CY/CF/C/KET/KE/CG/P/Q/PL/SE/PO/KT/ABU/J'
    #                          I_O_CABLE_LENGTH => '0/2/3/5'
    #                          MOTOR_TYPE => '600/56SP/150/56/28S/1000/35/35P/28SP/56P/
    #                                         60/20SP/35S/100/28/86P/56S/42P/30D/20P/750/
    #                                         200/300/42/20/42SP/35SP/400/42S/30R/28P/20S'
    def parse(model_serie_row, model_serie_spec, master_data_rows = {}, screen_combinded_reference_rows = {})
      raise 'ScreemCombinedReference not specified' if model_serie_row.nil?
      
      options_and_groups = parse_options_and_parse_groups(
        model_serie_spec.to_s.strip,
        model_serie_row,
        master_data_rows,
        screen_combinded_reference_rows
      )

      value = {
        :scr_row_id => model_serie_row.id
      }.update(options_and_groups)

      value[:error_messages] = []
      value[:error_messages] << 'Invalid data_format value' unless is_valid?(model_serie_spec)
      options = [value[:options]] +  value[:groups].values.collect{|v| v[:options] }.compact
      value[:error_messages] += options.collect{|h| h.values.collect{|v| v[:error_messages] } }.flatten.compact

      value.delete(:error_messages) if value[:error_messages].empty?
      value.delete(:groups) if value[:groups].empty?

      value
    end

    def is_valid?(model_serie_spec)
      valid_over_all = !(model_serie_spec =~ ocr_reqexp).nil?

      valid_over_all
    end
    
    def find_all_rows(model_serie_row_or_screen_ids, related_from_custom_fields = {})
      result = {}
      
      case model_serie_row_or_screen_ids
      when Array
        screen_ids = model_serie_row_or_screen_ids
      else
        model_serie_row = model_serie_row_or_screen_ids
        screen_ids = model_serie_row.screen_combined_screen_ids +
          model_serie_row.screen_combined_screen_group_ids +
          model_serie_row.screen_combined_option_screen_ids
      end
      
      dup_codes = {}
        
      screen_ids.each do |s_id|
        result[s_id] = {}

        screen = Screen.find(s_id)
        
        raise "Unique field not set for screen #{screen.name}" if screen.unique_fields.empty?

        rows = {}
        screen.rows.each{|r| rows[r.id] = r }
        
        vm = VirtualMemory.load(:screen_index, s_id)
        
        row_ids = vm[:reverse] ||= {}
        
        row_ids.each do |r_id, keys|
          code = keys.first.split(/ /).first.upcase

          if result[s_id][code].nil?
            result[s_id][code] = rows[r_id]
            result[s_id][r_id] = rows[r_id]
          else
            dup_codes[screen.name] ||= []
            dup_codes[screen.name] << code
            dup_codes[screen.name].uniq!
          end
        end
      end
      
      raise "Duplicate value in the following screens...<pre>#{dup_codes.to_yaml}</pre>" unless dup_codes.empty?

      result
    end
    
    private

    def any_pattern
      '\\*'
    end

    def option_pattern(codes)
      codes.nil? ? "[\\w\\.]+" : "(#{codes.collect{|c| c.gsub(/([\.\/])/, '\\ \1').gsub(/ /, '') }.join('|')})"
    end

    def options_pattern(codes)
      "(#{option_pattern(codes)}\\/)*#{option_pattern(codes)}"
    end
    
    def wrapped_options_pattern(codes)
      "\\[#{options_pattern(codes)}\\]"
    end

    def delimiter_pattern
      "(#{CustomFields::ScreenCombindedReference.delimiter.join('|')})?"
    end
    
    def option_value_pattern(codes = nil)
      "#{delimiter_pattern}(#{any_pattern}|#{wrapped_options_pattern(codes)}|#{options_pattern(codes)})"
    end
    
    def ocr_pattern
      "(#{option_value_pattern}*)+"
    end

    def option_value_reqexp(codes = nil)
      /^(#{option_value_pattern(codes)})/i
    end

    def ocr_reqexp
      @@ocr_reqexp = /^#{ocr_pattern}$/i
    end
#
#    def ocr_pattern(model_serie_row, master_data_rows = [])
#      masks = CustomFields::SCR.cell_masks(model_serie_row.screen_combined_cell.value, false).join
#      master_data_rows.each do |s_id, rows|
#        masks.gsub!(/\[#{s_id}\]/, option_patterns(rows.keys))
#      end
#      masks.gsub!(/\{.+?\}/, '+')
#
#      masks
#    end

    def parse_options_and_parse_groups(model_serie_spec, model_serie_row, master_data_rows = {}, screen_combinded_reference_rows = {}, remain_spec = nil)
      merge_remainings = remain_spec.nil?
      remain_spec = model_serie_spec.clone if remain_spec.nil?
      model_serie_cell_value = model_serie_row.screen_combined_cell.value
      parts = CustomFields::ScreenCombindedReference.cell_parts(model_serie_cell_value)

      options = {}
      groups = {}
      
      parts.each_with_index {|p, i|
        next if p[:type] == :option
        
        raise "Screen id '#{p[:screen_id]}' wasn't found in the Master Data Cache" if master_data_rows[p[:screen_id]].nil? && p[:screen_id] > 0

        rows = master_data_rows[p[:screen_id]]
        
        case p[:type]
        when :screen
          row_codes = rows.keys.select{|k| k.is_a?(String)}.sort{|a, b| b <=> a }

          spec = ''
          step = 1000
          
          0.step(row_codes.size-1, step) do |n|
            reqexp = option_value_reqexp(row_codes[n...n+step])

            if remain_spec.match(reqexp)
              specs = remain_spec.gsub(reqexp, '\1|').split('|')
              spec = specs.first.to_s.gsub(/[\[\]]/, '')
              remain_spec.gsub!(reqexp, '')

              break
            end
          end
          
          raise "Invalid spec. No value specified for '#{Screen.find(p[:screen_id]).label_descr}'" if spec.empty?

          is_muliplier_screen = CustomFields::ScreenCombindedReference.is_screen_used_as_multiply_count?(model_serie_cell_value, p[:screen_id])
          raise "Invalid spec. Only one value can be specified for the Multiplier '#{spec}'" if is_muliplier_screen && spec =~ /\//

          spec << remain_spec if merge_remainings && p == parts.last

          options[i.to_s] = parse_options(spec, rows)
        when :group
          grp_scr_row = screen_combinded_reference_rows[p[:screen_combinded_reference_row_id]]

          raise "Missing Screen Combined Reference row id #{p[:screen_combinded_reference_row_id]}" if grp_scr_row.nil?

          screen_ids = CustomFields::ScreenCombindedReference.cell_screen_ids(model_serie_cell_value)
          
          if p[:screen_id] < 0
            field_values = [model_serie_row.screen_combined_code]
          else
            raise "Muliplier Screen '#{Screen.find(p[:screen_id]).name}' hasn't been set yet " if options[screen_ids.index(p[:screen_id]).to_s].nil?

            muliplier_row_id = options[screen_ids.index(p[:screen_id]).to_s][:row_ids].first

            raise "Missing key '#{muliplier_row_id}'" unless rows.has_key?(muliplier_row_id)

            muliplier_row = rows[muliplier_row_id]

            raise "Muliplier Row id '#{muliplier_row_id}' doesn't exist " if muliplier_row.nil?

            field_values = muliplier_row.description.split(/ - /)
          end
          
          field_values = field_values.collect{|v| v.gsub(/[^\d]/, '') if v =~ /[\d]/}.compact

          n = [field_values.first.to_i, 1].max

          options[i.to_s] = { :group	=> n }
          
          (0..n-1).each do |g|
            groups[g.to_s] = parse_options_and_parse_groups('', grp_scr_row, master_data_rows, {}, remain_spec)
            groups[g.to_s].delete(:groups)
          end
        end
      }
      
      {
        :options => options,
        :groups => groups
      }
    end

    def parse_options(spec, master_data_rows = {})
      result = { :row_ids => [] }
      
      row_codes = spec.gsub(/^-/, '').split(/\//)
      row_codes.each do |c|
        row = master_data_rows[c]

        raise "Invalid spec '#{spec}'. Row code '#{c}' wasn't found in the Master Data Cache" if row.nil?

        result[:row_ids] << row.id
      end

      result
    end
  end

  def validate_filters(search_filter, require_search)
    search_filter = { :scr_row_id => search_filter } unless search_filter.is_a?(Hash)

    scr_row_id = search_filter[:scr_row_id].to_i

    required_filter = (require_search && scr_row_id == 0)
    invalid_filter = scr_row_id < 0
    return {:required => required_filter, :invalid => invalid_filter}
  end

  def search_value?(value, filter)
    return true if filter.nil?
    
    filter = { :scr_row_id => filter, :text => '', :row_id => 0 } unless filter.is_a?(Hash)

    scr_row_id = filter[:scr_row_id].to_i
    ocr_text = filter[:text].to_s.strip
    
    if CustomFields::OptionCombindedReference.cell_scr_row_id(value) == scr_row_id
      unless ocr_text.empty?
        ocr_row_id = filter[:row_id].to_i

        ocr_patterns = index_lookup(scr_row_id, filter[:screen_id], nil,
          { :fetch => :patterns, :ocr_row => ocr_row_id }
        )
      end

      ocr_text.empty? || ocr_patterns.any?{|p| !(p =~ /^#{Regexp.escape(ocr_text)}/i).nil?}
    else
      false
    end
  end
  
  def description
    'Option Combinded Reference'
  end
  
  def absolute_value(value, options = {})
    defaults = {
      :include_delimiter => false,
      :wrap_groups => true
    }
    options = defaults.merge(options)
    
    scr_row_id = CustomFields::OptionCombindedReference.cell_scr_row_id(value)
    
    return [Row.missing_msg(scr_row_id)] unless Row.exists?(scr_row_id)
    
    scr_row = Row.find(scr_row_id)
    main_scr_parts = scr_row.screen_combined_cell.value[:parts]
    
    result = [scr_row.screen_combined_code]
    result << ':' if options[:include_delimiter]
    
    opt_options = CustomFields::OptionCombindedReference.cell_options(value,false).flatten
    opt_options.each_with_index do |option, main_index|
      if option.has_key?(:group)
        sub_scr_row_id = scr_row.screen_combined_cell.value[:parts][main_index][:screen_combinded_reference_row_id]
        sub_scr_row = Row.find(sub_scr_row_id)
        sub_scr_parts = sub_scr_row.screen_combined_cell.value[:parts]

        row = ''
        groups = CustomFields::OptionCombindedReference.cell_groups(value).flatten
        groups.each do |group|
          sub_row = []
          group.each do |sub_index, o|
            if o[:row_ids].is_a?(Array) then
              o[:row_ids].collect!{|r_id| r_id.to_i if r_id.to_i > 0 }
              o[:row_ids].compact!
              
              sub_row << "#{sub_scr_parts[sub_index.to_i][:delimiter]}#{row_selected(o[:row_ids])}"
            end
          end
          row << (options[:wrap_groups] ? "(#{sub_row.join})" : sub_row.join)
        end

        result << [row]
      else
        row_ids = option[:row_ids].uniq
        
        #~ ToDo: Need to filter the scr screen's rows to match the "RelatedFrom" field condition
        # if (scr_row.screen_combined_screens[k].row_ids - row_ids).empty?
        #   result << '*'
        # else
        result << main_scr_parts[main_index.to_i][:delimiter] if options[:include_delimiter]
        result << row_selected(row_ids)
        # end
        
      end
    end

    result
  end

  def text(value)
    absolute_value(value, :include_delimiter => true, :wrap_groups => false).join
  end

  def html(value)
    absolute_value(value)
  end

  def parse(value, options={})
    defaults = {
      :scr_rows => {},
      :master_data_rows => {}
    }
    options = defaults.merge(options)
    
    parts = value.split(/:/)

    model_serie_code = parts.first
    model_serie_spec = parts[1...parts.size].join(':')
    
    model_serie_row = options[:scr_rows][model_serie_code]

    raise "Invalid spec '#{value}'. SCR code '#{model_serie_code}' wasn't found in the Master Data Cache" if model_serie_row.nil?

    ocr_value = CustomFields::OptionCombindedReference.parse(model_serie_row, model_serie_spec, options[:master_data_rows], options[:scr_rows])

    raise ocr_value[:error_messages].inspect if ocr_value.has_key?(:error_messages)

    ocr_value
  end

  def is_empty?(cell_value)
    is_empty = (CustomFields::OptionCombindedReference.cell_scr_row_id(cell_value) <= 0)
    is_empty ||= CustomFields::OptionCombindedReference.cell_options(cell_value).flatten.any?{|o| o[:row_ids].empty? }

    is_empty
  end
  
  def regexp(value, length, result = nil)
    if result.nil?
      options = CustomFields::OptionCombindedReference.cell_options(value).flatten
      result = options[0...length].collect{|o| o[:row_ids].join('|') unless o.has_key?(:group) }.compact
    end
    
    a = result[0...length].collect{|o| "(\\*|#{o.to_s})"}.join('-')

    Regexp.new('^' + a, Regexp::EXTENDED)
  end

  def special_values(screen)
    fields = Fields::Data.find(:all)
    fields.collect{|f| f if f.custom_field.is_a?(CustomFields::ScreenCombindedReference) }.compact
  end

  def has_index?(screen_id, cache_vm = nil)
    vm_id = "#{self[:id]}_#{screen_id}"
    vm = cache_vm || VirtualMemory.load(:custom_field_index, vm_id)

    vm[:env] == Rails.env && vm.has_key?(:root) && vm[:screen_id].to_i == screen_id.to_i
  end
  
  def index_lookup(scr_row_id, screen_id, cache_vm = nil, options = {})
    defaults = {
      :ocr_row => nil,
      :fetch => :cells
    }
    options = defaults.merge(options)
    
    vm_id = "#{self[:id]}_#{screen_id}"
    
    vm = cache_vm || VirtualMemory.load(:custom_field_index, vm_id)
    
    unless has_index?(screen_id, vm)
      screen = Screen.find(screen_id)
      rebuild_index_by_screen(screen, nil, false)

      vm = VirtualMemory.load(:custom_field_index, vm_id)
    end


    ocr_row = options[:ocr_row]

    case options[:fetch]
    when :patterns
      case ocr_row
      when Row
        ocr_row.option_combined_patterns
      when Fixnum, String
        row_vm = VirtualMemory.load(:row_cache, ocr_row)

        row_vm[:option_combined_patterns] || Row.find(ocr_row).option_combined_patterns
      else
        raise 'Pass :ocr_row => (Row|Fixnum|String) when using :fetch => :patterns'
      end
    when :row_ids
      case ocr_row
      when Row
        ocr_patterns = ocr_row.option_combined_patterns
      when Hash
        ocr_patterns = CustomFields::OptionCombindedReference.cell_ocr_patterns(self, ocr_row)
      else
        raise 'Pass :ocr_row => (Row|Hash) when using :fetch => :row_ids'
      end
      
      vm[:root][scr_row_id] ||= []
      vm[:root][scr_row_id].collect do |r_id|
        row_vm = VirtualMemory.load(:row_cache, r_id)

        row_ocr_patterns = row_vm[:option_combined_patterns] || Row.find(r_id).option_combined_patterns
        
        r_id unless (ocr_patterns & row_ocr_patterns).empty?
      end.compact
    else
      row_ids = vm[:root][scr_row_id] || []

      cells = Cell.find(:all,
          :conditions => {
            :row_id => row_ids, :field_id => self[:id]
          }
        )

      cells || []
    end 
  end

  def index_remove(row, remove)
    rebuild_index(row, remove)
  end

  def index_store(row)
    rebuild_index(row)
  end

  def rebuild_index(row = nil, remove = false, options = {})
    screens = row.nil? ? self.fields.collect{|f| f.screen } : [row.screen]
    screens.each{|s| rebuild_index_by_screen(s, row, remove, options) }
  end

  def rebuild_index_by_screen(screen, row, remove, options = {})
    defaults = {
      :report_progress => false
    }
    options = defaults.merge(options)
    
    vm_id = "#{self[:id]}_#{screen.id}"

    vm = VirtualMemory.load(:custom_field_index, vm_id)

    vm[:env] = Rails.env
    vm[:root] = {} if vm[:root].nil? || row.nil?
    vm[:updated_at] = Time.now
    vm[:screen_id] = screen.id

    row_ids = row.nil? ? screen.row_ids : [row.id]

    block_size = 100
    
    0.step(row_ids.size, block_size) do |i|
      GC.start

      row_block = row.nil? ? Row.find(row_ids[i...i+block_size]) : [row]
      
      vm[:root] ||= {}
      vm[:root][scr_row_id] ||= []
      
      row_block.each do |r|
        if remove
          vm[:root].keys.each do |scr_row_id|
            vm[:root][scr_row_id].delete(r.id)
            r.clear_option_combined_patterns
          end
        else
          scr_row_id = CustomFields::OptionCombindedReference.cell_scr_row_id(r.cell(self[:id]).value)

          vm[:root][scr_row_id] << r.id
          
          #~ Call Row.option_combined_patterns to trigger cache
          r.clear_option_combined_patterns
          r.option_combined_patterns
        end
      end
      
      vm[:root][scr_row_id].uniq!
      
      if options[:report_progress] && row_ids.size > block_size
        n = [i+block_size, row_ids.size].min.to_s.rjust(row_ids.size.to_s.size, '0')
        percentage = 100.0*n.to_f/row_ids.size
        puts "#{n}/#{row_ids.size} [#{percentage.to_s[0..4]}%]"
      end

      VirtualMemory.store(:custom_field_index, vm_id, vm)
    end

    VirtualMemory.store(:custom_field_index, vm_id, vm)
  end

  private
  
  # return string
  def row_selected(row_ids)
    rows = Row.find(row_ids.select{|r_id| r_id.to_i > 0 })

    unless rows.empty? || rows.first.screen.nil?
      custom_field_id = rows.first.screen.non_ref_description_custom_field_ids.first
    end
    
    rows.first.screen.nil? ? Screen.missing_msg(rows.first.screen_id) : rows.collect{|r| r.description(custom_field_id) }.join('/') unless rows.empty?
  end

end

# Short alias for CustomFields::OptionCombindedReference
class CustomFields::OCR < CustomFields::OptionCombindedReference
  # Prevent this class from being created
  private_class_method :new
end

#    content = retrieve_option_combinded_reference_result(@gen_rows[row.id][cf.id])

