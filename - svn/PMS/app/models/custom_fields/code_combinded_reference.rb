# Stored value structure
#
# <b>CustomField</b>
#   custom_field.value = {
#       :separator => ”-”
#     }
#
# <b>Field</b>
#   field.value = {
#       :relate_to => 1,
#       :related_from => 2,
#       :field_id => 3,
#       :wildcard => 0/1 # Need to change to boolean (True/False),
#       :display_as => :None /:Radio /:CheckBox
#     }
#
# <b>Cell</b>
#   cell.value = {
#       :scr_row_id => 1,
#       :ocr_row_id => 9,
#       :selecteds => [
#           {:row_id => 11},
#           {:row_id => 21},
#           {:group => 2},
#           {:row_id => 41}
#         ],
#       :opt_row_ids => [-1, 10, 12],
#       :groups => {
#           0 => {
#               :selecteds => [
#                 {:row_id => 3111},
#                 {:row_id => 3121},
#                 {:row_id => 3131}
#               ],
#               :opt_row_ids => [-1, 3141, 3142]
#             },
#           1 => {
#               :selecteds => [
#                 {:row_id => 3211},
#                 {:row_id => 3221},
#                 {:row_id => 3231}
#               ],
#               :opt_row_ids => [-1, 3241, 3242]
#             },
#           2 => {
#               :selecteds => [
#                 {:row_id => 3311},
#                 {:row_id => 3321},
#                 {:row_id => 3331}
#               ],
#               :opt_row_ids => [-1, 3341, 3342]
#             }
#         }
#     }
#
# * If field.wildcard is True
#
#   cell.value = {
#       :scr_row_id => 1,
#       :ocr_row_id => nil, # value[:ocr_row_id] will be null
#       :selecteds => [
#           { :row_id => 2},
#           { :row_id => -1},
#           { :row_id => 4}
#         ]
#     }
#
# * If field.wildcard is False
#
#   cell.value = {
#       :scr_row_id => 1,
#       :ocr_row_id => 9,
#       :selecteds => [
#           {:row_id => 2},
#           {:row_id => 3},
#           {:row_id => 4}
#         ]
#     } 
#        
# * If CustomFields::CCR.field_display_as(field.value) == :none
#
#   cell.value = {
#       :scr_row_id => 1,
#       :ocr_row_id => 9,
#       :selecteds => [
#           ...,
#           {:group => 3},
#           ...
#         ],
#       :opt_row_ids => [-1],
#       :groups => {
#           0 => {
#               :selecteds => [...],
#               :opt_row_ids => [-1]
#             },
#           1 => {
#               :selecteds => [...],
#               :opt_row_ids => [-1]
#             },
#           2 => {
#               :selecteds => [...],
#               :opt_row_ids => [-1]
#             }
#         }
#     }
#
# * If CustomFields::CCR.field_display_as(field.value) == :radio
#
# *MainPattern*
#   cell.value = {
#       :scr_row_id => 1,
#       :ocr_row_id => 9,
#       :selecteds => [
#           ...,
#           {:group => 3},
#           ...
#         ],
#       :opt_row_ids => [10],
#       :groups => {...}
#     }
#
# *SubGroup*
#   cell.value = {
#       :scr_row_id => 1,
#       :ocr_row_id => 9,
#       :selecteds => [
#           ...,
#           {:group => 3},
#           ...
#         ],
#       :opt_row_ids => [-1],
#       :groups => {
#           0 => {
#               :selecteds => [...],
#               :opt_row_ids => [3141]
#             },
#           1 => {
#               :selecteds => [...],
#               :opt_row_ids => [-1]
#             },
#           2 => {
#               :selecteds => [...],
#               :opt_row_ids => [-1]
#             }
#         }
#     }
#
# * If CustomFields::CCR.field_display_as(field.value) == :check_box
#
#   cell.value = {
#       :text => 'ASEL-2-(A01-2)-(B02-3)-N2-D'
#       :scr_row_id => 1,
#       :ocr_row_id => 9,
#       :selecteds => [
#           ...,
#           {:group => 3},
#           ...
#         ],
#       :opt_row_ids => [-1, 10, 12],
#       :groups => {
#           0 => {
#               :selecteds => [...],
#               :opt_row_ids => [-1, 3141, 3142]
#             },
#           1 => {
#               :selecteds => [...],
#               :opt_row_ids => [-1, 3241, 3242]
#             },
#           2 => {
#               :selecteds => [...],
#               :opt_row_ids => [-1, 3341, 3342]
#             }
#         }
#     }
class CustomFields::CodeCombindedReference < CustomField

  class << self
    def row_in_use?(row_id, ccr_cells, all = false)
      row_in_use_by = []

      ccr_cells.each do |ccr_c|
        selecteds = cell_selecteds(ccr_c[:value])

        next if selecteds.empty?
        
        row_ids = selecteds.flatten.collect{|s| s[:row_id] }.flatten.uniq

        row_in_use_by << ccr_c.row if row_ids.include?(row_id)

        break unless all || row_in_use_by.empty?
      end

      all ? row_in_use_by : row_in_use_by.first
    end

    #   CustomFields::CCR.field_relate_to(Hash)  -> int
    #
    # Get the value for the :relate_to key
    #   CustomFields::CCR.field_relate_to({:relate_to => 1}) #=> 1
    #   CustomFields::CCR.field_relate_to({})                #=> 0
    #   CustomFields::CCR.field_relate_to(nil)               #=> 0
    def field_relate_to(field_value)
      field_value ||= {}

      field_value[:relate_to].to_i
    end

    #   CustomFields::CCR.field_related_from(Hash) -> int
    #
    # Get the value for the :related_from key
    #   CustomFields::CCR.field_related_from({:related_from => 1}) #=> 1
    #   CustomFields::CCR.field_related_from({})                   #=> 0
    #   CustomFields::CCR.field_related_from(nil)                  #=> 0
    def field_related_from(field_value)
      field_value ||= {}

      field_value[:related_from].to_i
    end

    #   CustomFields::CCR.field_ocr_field_id(Hash) -> int
    #
    # Get the value for the :field_id key
    #   CustomFields::CCR.field_ocr_field_id({:field_id => 1}) #=> 1
    #   CustomFields::CCR.field_ocr_field_id({})               #=> 0
    #   CustomFields::CCR.field_ocr_field_id(nil)              #=> 0
    def field_ocr_field_id(field_value)
      field_value ||= {}

      field_value[:field_id].to_i
    end

    #   CustomFields::CCR.field_wildcard(Hash) -> true or false
    #
    # Get the value for the :related_from key
    #   TrueClass - true
    #   FalseClass - false
    #   String - If value is /true/i will returns true; otherwise false
    #   Non-Null - All non-zero values will return true
    #   
    #   CustomFields::CCR.field_wildcard({:wildcard => 1})        #=> true
    #   CustomFields::CCR.field_wildcard({:wildcard => 0})        #=> false
    #   CustomFields::CCR.field_wildcard({:wildcard => true})     #=> true
    #   CustomFields::CCR.field_wildcard({:wildcard => false})    #=> false
    #   CustomFields::CCR.field_wildcard({:wildcard => 'true'})   #=> true
    #   CustomFields::CCR.field_wildcard({:wildcard => 'false'})  #=> false
    #   CustomFields::CCR.field_wildcard({:wildcard => 'text'})   #=> false
    #   CustomFields::CCR.field_wildcard({})                      #=> false
    #   CustomFields::CCR.field_wildcard(nil)                     #=> false
    # require 'custom_fields/code_combinded_reference'
    def field_wildcard(field_value)
      field_value ||= {}

      case field_value[:wildcard]
      when TrueClass, FalseClass then field_value[:wildcard]
      when String then (field_value[:wildcard] =~ /true/i) == 0
      else field_value[:wildcard].to_i != 0
      end
    end

    #   CustomFields::CCR.field_display_as(Hash) -> :None or :Radio or :CheckBox
    #
    # Get the value for the :display_as key
    #   CustomFields::CCR.field_display_as({:display_as => :Radio})  #=> :Radio
    #   CustomFields::CCR.field_display_as({})                       #=> :None
    #   CustomFields::CCR.field_display_as(nil)                      #=> :None
    def field_display_as(field_value)
      field_value ||= {}
      field_value[:display_as] ||= :None

      field_value[:display_as].to_sym
    end

    #   CustomFields::CCR.cell_scr_row_id(Hash) -> int
    #
    # Get the value for the :scr_row_id key
    #   CustomFields::CCR.cell_scr_row_id({:scr_row_id => 1}) #=> 1
    #   CustomFields::CCR.cell_scr_row_id({})                 #=> 0
    #   CustomFields::CCR.cell_scr_row_id(nil)                #=> 0
    def cell_scr_row_id(cell_value)
      cell_value = nil if cell_value.to_s.empty?
      cell_value ||= {}

      cell_value[:scr_row_id].to_i
    end
    
    #   CustomFields::CCR.cell_ocr_row_id(Hash) -> int
    #
    # Get the value for the :ocr_row_id key
    #   CustomFields::CCR.cell_ocr_row_id({:ocr_row_id => 1}) #=> 1
    #   CustomFields::CCR.cell_ocr_row_id({})                 #=> 0
    #   CustomFields::CCR.cell_ocr_row_id(nil)                #=> 0
    def cell_ocr_row_id(cell_value)
      cell_value = nil if cell_value.to_s.empty?
      cell_value ||= {}

      cell_value[:ocr_row_id].to_i
    end

    #   CustomFields::CCR.cell_selecteds(Hash) -> an_array
    #
    # Get the value for the :selecteds key, all id values will be integer
    #   cell_value = {
    #       :selecteds => [
    #           {:row_id => '2'},
    #           {:group => '2'},
    #           {:row_id => '3'},
    #           {:row_id => '4'}
    #         ],
    #       :groups => {
    #           '0' =>{
    #               :selecteds => [
    #                   {:row_id => '12'},
    #                   {:row_id => '13'}
    #                 ]
    #             },
    #           '1' =>{
    #               :selecteds => [
    #                   {:row_id => '22'},
    #                   {:row_id => '23'}
    #                 ]
    #             }
    #         }
    #     }
    #   CustomFields::CCR.cell_selecteds(cell_value)  #=> [
    #                                                 #     {:row_id => 2},
    #                                                 #     [
    #                                                 #       [{:row_id => "12"}, {:row_id => "13"}],
    #                                                 #       [{:row_id => "22"}, {:row_id => "23"}],
    #                                                 #     ],
    #                                                 #     {:row_id => 3},
    #                                                 #     {:row_id => 4}
    #                                                 #   ]
    #   CustomFields::CCR.cell_selecteds({})          #=> []
    #   CustomFields::CCR.cell_selecteds(nil)         #=> []
    def cell_selecteds(cell_value)
      cell_value = nil if cell_value.to_s.empty?
      cell_value ||= {}
      cell_value[:selecteds] ||= []

      if cell_value[:selecteds].is_a?(Hash)
        selecteds = cell_value[:selecteds]
        cell_value[:selecteds] = []
        selecteds.each{|k, v| cell_value[:selecteds][k.to_i] = v}
      end

      cell_value[:selecteds].collect do |v|
        if v.has_key?(:group)
          cell_value[:groups] ||= {}

          (0..v[:group].to_i-1).collect{|g| cell_selecteds(cell_value[:groups][g.to_s])}
        else
          v[:row_id] = v[:row_id].to_i
        
          v
        end
      end
    end

    #   CustomFields::CCR.cell_opt_row_ids(Hash) -> an_array
    #
    # Get the value for the :opt_row_ids key, all id values will be integer
    #   cell_value = {
    #       :selecteds => [
    #           {:group => '2'}
    #         ],
    #       :opt_row_ids => [1,2,3],
    #       :groups => {
    #           '0' =>{
    #               :opt_row_ids => [11,12,13]
    #             },
    #           '1' =>{
    #               :opt_row_ids => [21,22,23]
    #             }
    #         }
    #     }
    #   CustomFields::CCR.cell_opt_row_ids(cell_value) #=> [[11,12,13],[21,22,23],1,2,3]
    #   CustomFields::CCR.cell_opt_row_ids({})         #=> []
    #   CustomFields::CCR.cell_opt_row_ids(nil)        #=> []
    def cell_opt_row_ids(cell_value)
      cell_value = nil if cell_value.to_s.empty?
      cell_value ||= {}
      cell_value[:selecteds] ||= []
      cell_value[:opt_row_ids] ||= []

      group = cell_value[:selecteds].select{|s| s.has_key?(:group) }.first

      opt_row_ids = []

      unless group.nil?
        cell_value[:groups] ||= {}
          
        opt_row_ids += (0..group[:group].to_i-1).collect{|g| cell_opt_row_ids(cell_value[:groups][g.to_s])}
      end
      
      opt_row_ids += cell_value[:opt_row_ids].collect do |v|
        v.to_i if v.to_i > 0
      end.compact
    end

    #   CustomFields::CCR.cell_opt_row_ids(Hash) -> an_array
    #
    # Get the value for the :opt_row_ids key, all id values will be integer
    #
    # SCR w sub-group
    #   cell_value = {
    #       :selecteds => [
    #           {:row_id => 1},
    #           {:group => '2'}
    #         ],
    #       ...
    #     }
    #   CustomFields::CCR.cell_multiplier_row_id(cell_value) #=> 1
    #
    # SCR w/o sub-group
    #   cell_value = {
    #       :selecteds => [
    #           {:row_id => 1}
    #         ],
    #       ...
    #     }
    #   CustomFields::CCR.cell_multiplier_row_id(cell_value) #=> 0
    #   CustomFields::CCR.cell_multiplier_row_id({})         #=> 0
    #   CustomFields::CCR.cell_multiplier_row_id(nil)        #=> 0
    def cell_multiplier_row_id(cell_value, scr_row)
      scr_cell_value = scr_row.screen_combined_cell.value
      multiplier_screen_index = CustomFields::ScreenCombindedReference.cell_multiplier_index(scr_cell_value)

      if multiplier_screen_index == -1
        scr_row.id
      else
        cell_value ||= {}
        cell_value[:selecteds] ||= []
        cell_value[:selecteds][multiplier_screen_index] ||= {}

        cell_value[:selecteds][multiplier_screen_index][:row_id].to_i
      end
    end

    #   CustomFields::CCR.cell_text(cell_value) #=> "AAA-BBB-CCC-DDD"
    #   CustomFields::CCR.cell_text({})         #=> ""
    #   CustomFields::CCR.cell_text(nil)        #=> ""
    def cell_text(cell_value)
      cell_value = nil if cell_value.to_s.empty?
      cell_value ||= {}
      cell_value[:text] ||= ''
      
      cell_value[:text]
    end

    #   CustomFields::CCR.cell_text(cell_value) #=> "AAA-BBB-CCC-DDD"
    #   CustomFields::CCR.cell_text({})         #=> ""
    #   CustomFields::CCR.cell_text(nil)        #=> ""
    def cell_cached_text(cell_value)
      cell_value = nil if cell_value.to_s.empty?
      cell_value ||= {}
      cell_value[:cached_text] ||= ''

      cell_value[:cached_text]
    end

    def set_cell_ocr_row_id(ccr_cf, row_id, new_ocr_row_id)
      row = Row.find(row_id)
      cell = row.cell(ccr_cf.id)
      cell.value[:ocr_row_id] = new_ocr_row_id
      cell.save
    end

    #
    # replace_ocr_row_id(cf, 288204, 288631)
    # replace_ocr_row_id(cf, 288207, 288632)
    def replace_cell_ocr_row_id(ccr_cf, old_ocr_row_id, new_ocr_row_id)
      cnt = 0
      ccr_cf.cells.each do |cell|
        if cell.value[:ocr_row_id].to_i == old_ocr_row_id.to_i
          cell.value[:ocr_row_id] = new_ocr_row_id
          cell.save
          cnt += 1
        end
      end

      cnt
    end


    def option_combined_reference_values(scr_row_id, screen_id, custom_field_id)
      cells = Cell.find(:all,
        :joins => [:row],
        :conditions => ['rows.screen_id = ? and cells.field_id = ? ',
          screen_id, custom_field_id])
      cells.select{|c| c.value[:scr_row_id].to_i == scr_row_id }
    end

    def code_combined_reference_values(scr_row_id, field)
      option_combined_reference_values(scr_row_id, field.screen_id, field.custom_field_id)
    end
    
    def find_all
      @@all_custom_field_ccrs = nil unless CustomField.instance_cached?
      @@all_custom_field_ccrs ||= CustomFields::CodeCombindedReference.find(:all)

      @@all_custom_field_ccrs.clone
    end

    #   cell.value = {
    #       :scr_row_id => 1,
    #       :ocr_row_id => nil, # value[:ocr_row_id] will be null
    #       :selecteds => [
    #           { :row_id => 2},
    #           { :row_id => -1},
    #           { :row_id => 4}
    #         ]
    #     }
    def parse(scr_row, model_serie_spec, master_data_rows = {}, screen_combinded_reference_rows = {}, source_ocr_field = nil)
      options_and_groups = parse_selecteds_and_parse_groups(
        model_serie_spec.to_s.strip,
        scr_row,
        master_data_rows,
        screen_combinded_reference_rows
      )
      
      ocr_row_id = nil
      
      unless source_ocr_field.nil?
        @cached_ocr_cell_keys ||= []
        @cached_ocr_cells ||= []

        if @cached_ocr_cell_keys != [scr_row.id, source_ocr_field.screen_id, source_ocr_field.custom_field_id]
          @cached_ocr_cell_keys = [scr_row.id, source_ocr_field.screen_id, source_ocr_field.custom_field_id]
          @cached_ocr_cells = CustomFields::CodeCombindedReference.option_combined_reference_values(scr_row.id, source_ocr_field.screen_id, source_ocr_field.custom_field_id)
        end

        selected_part_options = CustomFields::CodeCombindedReference.cell_selecteds(options_and_groups).flatten.collect{|h| h[:row_id]}

        test_text_to_search = selected_part_options.join('-')
        index = selected_part_options.size

        @cached_ocr_cells.each do |c|
          match = !c.regexp(index).match(test_text_to_search).nil?
          ocr_row_id = c.row_id if match
          break if ocr_row_id
        end
      end
      
      value = {
        :scr_row_id => scr_row.id,
        :ocr_row_id => ocr_row_id
      }.update(options_and_groups)

      value[:error_messages] = []
      value[:error_messages] << 'Invalid data_format value' unless is_valid?(model_serie_spec)
      options = value[:selecteds] + value[:groups].values.collect{|v| v[:selecteds] }.flatten.compact
      value[:error_messages] += options.collect{|h| h[:error_messages] }.flatten.compact

      value.delete(:error_messages) if value[:error_messages].empty?
      value.delete(:groups) if value[:groups].empty?

      value
    end

    def is_valid?(model_serie_spec)
      valid_over_all = !(model_serie_spec =~ ccr_reqexp).nil?

      valid_over_all
    end

    def ccr_text(scr_row, selected_options, include_scr_code = true)
      parts = CustomFields::ScreenCombindedReference.cell_parts(scr_row.screen_combined_cell.value)
      
      text = "#{scr_row.screen_combined_code if include_scr_code}"
      
      i = 0
      parts.each do |p|
        case p[:type]
        when :screen
          r_id = selected_options[i]

          break unless r_id.to_i > 0

          row = Row.find(r_id)

          unless row.nil? || row.screen.nil?
            custom_field_id = row.screen.non_ref_description_custom_field_ids.first
          end

          code = row.screen.nil? ? Screen.missing_msg(row.screen_id) : row.description(custom_field_id) unless row.nil?
          delimiter = p[:delimiter]
          text << "#{delimiter}#{code}"
          
          i += 1
        when :group
          sub_scr_row = Row.find(p[:screen_combinded_reference_row_id])
          sub_parts = CustomFields::ScreenCombindedReference.cell_parts(sub_scr_row.screen_combined_cell.value)
          sub_block_size =  sub_parts.select{|p| p[:type] == :screen }.size
          
          trial_screens = parts.size - i - 1
          next_screen_index = selected_options.size - trial_screens
          
          i.step(next_screen_index-1, sub_block_size) {|j|
            text << ccr_text(sub_scr_row, selected_options[j...j+sub_block_size], false)
          }
          
          i = next_screen_index
        end
      end

      text
    end

    private

    def any_pattern
      '\\*'
    end

    def value_pattern(codes = nil)
      codes.nil? ? "[\\w\\.]+" : "#{codes.collect{|c| c.gsub(/([\.\/])/, '\\ \1').gsub(/ /, '') }.join('|')}"
    end

    def delimiter_pattern
      "(#{CustomFields::ScreenCombindedReference.delimiter.join('|')})?"
    end

    def option_value_pattern(codes = nil)
      "#{delimiter_pattern}(#{any_pattern}|#{value_pattern(codes)})"
    end

    def ccr_pattern
      "(#{option_value_pattern}*)+"
    end

    def option_value_reqexp(codes = nil)
      /^(#{option_value_pattern(codes)})/i
    end

    def ccr_reqexp
      @@ccr_reqexp = /^#{ccr_pattern}$/i
    end
    
    def parse_selecteds_and_parse_groups(model_serie_spec, scr_row, master_data_rows = {}, screen_combinded_reference_rows = {}, remain_spec = nil)
      merge_remainings = remain_spec.nil?
      remain_spec = model_serie_spec.clone if remain_spec.nil?

      parts = CustomFields::ScreenCombindedReference.cell_parts(scr_row.screen_combined_cell.value)

      selecteds = []
      opt_row_ids = [-1]
      groups = {}
      
      parts.each_with_index {|p, i|
        screen = Screen.find(p[:screen_id]) if p[:screen_id] > 0
        screen_descr = 'Screen '
        screen_descr << (screen.nil? ? "id '#{p[:screen_id]}'" : "'#{screen.label_descr}'")

        rows = master_data_rows[p[:screen_id]]

        raise "#{screen_descr} wasn't found in the Master Data Cache" if p[:screen_id] > 0 && rows.nil?

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

          raise "Invalid spec. Unable to look up the '#{remain_spec}' value specified for position #{i+1}, for #{screen_descr}" if spec.empty?

          spec << remain_spec if merge_remainings && p == parts.last

          selecteds[i] = parse_selecteds(spec, rows)
        when :group
          grp_scr_row = screen_combinded_reference_rows[p[:screen_combinded_reference_row_id]]

          raise "Missing Screen Combined Reference row id #{p[:screen_combinded_reference_row_id]}" if grp_scr_row.nil?

          screen_ids = CustomFields::ScreenCombindedReference.cell_screen_ids(scr_row.screen_combined_cell.value)

          if p[:screen_id] < 0
            field_values = [scr_row.screen_combined_code]
          else
            raise "Muliplier Screen '#{Screen.find(p[:screen_id]).name}' hasn't been set yet " if selecteds[screen_ids.index(p[:screen_id])].nil?

            muliplier_row_id = selecteds[screen_ids.index(p[:screen_id])][:row_id]

            if muliplier_row_id > 0
              raise "Missing key '#{muliplier_row_id}'" unless rows.has_key?(muliplier_row_id)

              muliplier_row = rows[muliplier_row_id]

              raise "Muliplier Row id '#{muliplier_row_id}' doesn't exist " if muliplier_row.nil?

              field_values = muliplier_row.description.split(/ - /)
            else
              field_values = ['*']
            end
          end

          field_values = field_values.collect{|v| v.gsub(/[^\d]/, '') if v =~ /[\d]/}.compact

          n = [field_values.first.to_i, 1].max

          selecteds[i] = { :group	=> n }

          (0..n-1).each do |g|
            groups[g.to_s] = parse_selecteds_and_parse_groups('', grp_scr_row, master_data_rows, {}, remain_spec)
            groups[g.to_s].delete(:groups)
          end
        when :option
          opt_row = nil

          row_codes = rows.keys.select{|k| k.is_a?(String)}.sort{|a, b| b <=> a }

          reqexp = option_value_reqexp(row_codes)

          specs = remain_spec.gsub(reqexp, '\1|').split('|')
          spec = specs.first.to_s.gsub(/[\[\]]/, '').gsub(/^#{delimiter_pattern}/, '')
          
          until (spec.empty?)
            #~ ToDo: Extract option for the specified option screen.
            # Must support multiple value in the same screen
            # if screen_code.nil?
            option_screen_ids = scr_row.screen_combined_option_screen_ids
            # else
            #   option_screen = screen_by_name(screen_code.gsub(/[\[\]]/, ''))
            #
            #   raise "Missing Option Screen '#{screen_code}'" if option_screen.nil?
            #
            #   option_screen_ids = [option_screen.id]
            # end

            option_screen_ids.each do |s_id|
              #~ ToDo: Need to support filtered rows.
              # Original version separated data by SUSBKK IAI Product Series
              # master_data_rows[main_ps_row.id][s_id][option_code]
              opt_row = master_data_rows[s_id][spec]
              break unless opt_row.nil?
            end

            if !opt_row.nil?
              remain_spec.gsub!(reqexp, '')

              opt_row_ids << opt_row.id

              specs = remain_spec.gsub(reqexp, '\1|').split('|')
              spec = specs.first.to_s.gsub(/[\[\]]/, '').gsub(/^#{delimiter_pattern}/, '')
            elsif model_serie_spec.empty?
              break
            else
              raise "Row code '#{scr_row.description}':'#{spec}' wasn't found in the Option screens #{option_screen_ids.collect{|s_id| Screen.find(s_id).label_descr }.inspect }"
            end
          end
        end
      }

      {
        :selecteds => selecteds,
        :opt_row_ids => opt_row_ids,
        :groups => groups
      }
    end

    def parse_selecteds(spec, master_data_rows = {})
      result = { :row_id => -1 }

      row_code = spec.gsub(/^-/, '')
      
      unless row_code =~ /^\*$/
        row = master_data_rows[row_code]

        raise "Row code '#{row_code}' wasn't found in the Master Data Cache" if row.nil?

        result[:row_id] = row.id
      end

      result
    end
  end

  def search_value?(value, filter)
    return true if filter.nil?

    scr_row_id = CustomFields::CodeCombindedReference.cell_scr_row_id(value)
    scr_row = Row.find(scr_row_id)

    if filter.to_s.strip =~ /^#{scr_row.description}/
      str_value = text(value)
      !(str_value =~ /#{Regexp.escape(filter.to_s.strip)}/i).nil?
    end
  end
  
  def description
    'Code Combinded Reference'
  end
  
  def separator
    self[:value][:separator] ||= '-'
    @separator ||= ( " #{self[:value][:separator]} " unless self[:value][:separator].empty? ).to_s
  end

  def validate_value(cell_value, options = {})
    selecteds = cell_value.delete('selecteds') unless cell_value['selecteds'].nil?
    cell_value['selecteds'] = selecteds.is_a?(Array) ? selecteds : selecteds.keys.sort{|a, b| a.to_i <=> b.to_i }.collect{|k| selecteds[k] } unless selecteds.nil?
    cell_value['groups'].each do |i, v|
      selecteds = v.delete('selecteds') unless v['selecteds'].nil?
      v['selecteds'] = selecteds.is_a?(Array) ? selecteds : selecteds.keys.sort{|a, b| a.to_i <=> b.to_i }.collect{|k| selecteds[k] } unless selecteds.nil?
    end unless cell_value['groups'].nil?
    cell_value[:cached_text] = selected_text(cell_value)
    
    cell_value.keys.each do |k|
      if k.to_s =~ /^[0-9]+$/
        field_id = k.to_i
        if Field.exists?(field_id)
          field = Field.find(field_id)
          case field
          when Fields::ReferenceAttribute, Fields::CodeCombindedReferenceAttribute
            cell_value[k] = field.validate_value(cell_value[k])
          end
        end
      end
    end

    cell_value
  end

  def absolute_value(value, include_scr_code = true)
    validate_value(value)

    result = CustomFields::CodeCombindedReference.cell_text(value)
    result = CustomFields::CodeCombindedReference.cell_cached_text(value) if result.empty?
    
    result
  end

  def text(value)
    absolute_value(value)
  end

  def html(value)
    absolute_value(value)
  end

  def key_value(cell_value)
    text(cell_value)
  end

  def parse(value, options={})
    defaults = {
      :scr_rows => {},
      :master_data_rows => {},
      :source_ocr_field => nil
    }
    options = defaults.merge(options)

    model_serie_code = options[:scr_rows].keys.select{|k| k.is_a?(String) }.sort{|a,b| b <=> a }.select{|c| value =~ /^#{c}/}.first
    model_serie_spec = value.gsub(/^#{model_serie_code}/, '')

    model_serie_row = options[:scr_rows][model_serie_code]
    
    raise "Invalid spec '#{value}'. SCR code '#{model_serie_code}' wasn't found in the Master Data Cache" if model_serie_row.nil?
    
    ccr_value = CustomFields::CodeCombindedReference.parse(model_serie_row, model_serie_spec, options[:master_data_rows], options[:scr_rows], options[:source_ocr_field])

    raise ccr_value[:error_messages].inspect if ccr_value.has_key?(:error_messages)

    ccr_value
  end
  
  #  def regexp
  #    opt : /9-[52|53|54]-56-45-[21|22|23|24|25]-[21|22|23|24|25]/
  #    cod : /9-(0-9)+-56-45-(0-9)+-(0-9)+/
  #  end
  #
  #  def value
  #    "9-52-56-45-25-24" =~ regexp
  #  end

  def options(scr_row, field, selected_options, available_option = true)
    if selected_options.empty?
      VirtualMemory::store(:ccr_lookup_relations, ApplicationController.current_user.id, nil)
      VirtualMemory::store(:ccr_lookup_options, ApplicationController.current_user.id, nil)
      VirtualMemory::store(:ocr_lookup, ApplicationController.current_user.id, nil)
    end

    source_field = field.ocr_field
    cells = source_field.custom_field.index_lookup(scr_row.id, source_field.screen_id)
   
    test_text_to_search = selected_options.collect{|o| o.to_s.gsub(/^-1$/, '*')}.join('-')
    length = [selected_options].flatten.compact.size
    available_option_ids = []
    ocr_row = nil
    
    #~ ToDo: Cache the cells' regexp from length 0..max

    cells = cells.select do |c|
      c.regexp(length) =~ test_text_to_search
    end unless selected_options.empty?

    if available_option
      available_option_ids = cells.collect do |c|
        option = CustomFields::OptionCombindedReference.cell_options(c.value).flatten[length] || {}
        option[:row_ids]
      end.flatten.compact.uniq
    
      available_options = Row.find(:all, :conditions=>['id in (?)', available_option_ids])
    end
    
    if cells.size > 0
      ocr_row = cells.first.row
      
      ccr_text = CustomFields::CodeCombindedReference.ccr_text(scr_row, selected_options)
    end
    {
      :available_options => available_options,
      :ocr_row => ocr_row,
      :ccr_text => ccr_text
    }
  end
  
  def special_values(screen)
    fields = Fields::Data.find(:all)
    fields.collect{|f| f if f.custom_field.is_a?(CustomFields::OptionCombindedReference) }.compact
  end

  private

  # return string
  def row_selected(row_id) 
    if row_id == -1
      '*'
    else
      row = Row.find(row_id)

      row.description(row.screen.non_ref_description_custom_field_ids.first) unless row.nil?
    end.to_s
  end
  
  def selected_text(cell_value, include_scr_code = true)
    if cell_value[:text].to_s.empty? && Row.exists?(cell_value[:scr_row_id].to_i)
      row_screen = Row.find(cell_value[:scr_row_id].to_i)
      result = include_scr_code ? row_screen.screen_combined_code : ''

      parts = CustomFields::ScreenCombindedReference.cell_parts(row_screen.screen_combined_cell.value)

      selecteds = cell_value[:selecteds] || []

      parts.each_with_index do |p, i|
        r = selecteds[i]

        case p[:type].to_sym
        when :screen
          result << "#{p[:delimiter].strip}#{row_selected(r[:row_id].to_i)}"
        when :group
          (0...r[:group].to_i).each do |j|
            cell_value.store_value([:groups, j.to_s, :scr_row_id], p[:screen_combinded_reference_row_id])
            result << selected_text(cell_value[:groups][j.to_s], false)
          end
        when :option
          option_screen = Screen.find(p[:screen_id])
          opt_row_ids = option_screen.row_ids & (cell_value[:opt_row_ids] || []).collect{|r_id| r_id.to_i}
          result << opt_row_ids.collect{|r_id|
            "#{p[:delimiter]}#{row_selected(r_id)}" unless r_id == -1
          }.compact.join
        end
      end

    else
      result = "<span class='error_message'>SCR with ID=#{cell_value[:scr_row_id].to_i} is missing!</span>"
    end

    result || ''
  end
end

# Short alias for CustomFields::CodeCombindedReference
class CustomFields::CCR < CustomFields::CodeCombindedReference
  # Prevent this class from being created
  private_class_method :new
end
