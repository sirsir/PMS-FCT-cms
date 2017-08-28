# Stored value structure
#
# <b>CustomField</b>
#   custom_field.value = {
#       :screen_ids => [1, 2, 3, ...],
#       :option_screen_ids => [10, 11, 12, ...]
#     }
#
# <b>Field</b>
#   field.value = nil
#
# <b>Cell</b>
#   cell.value = {
#       :code => '...',
#       :parts => [
#         {
#           :delimiter => '-',
#           :type => :screen/:group/:option,
#           :screen_id => 1,
#           :screen_combinded_reference_row_id => 99
#         },
#         {...},
#         {...},
#       ]
#     }
class CustomFields::ScreenCombindedReference < CustomField

  class << self

    def part_type
      [:screen, :group, :option]
    end

    def delimiter
      [' ', '-']
    end

    def group_rows(field)
      Row.find(:all,
        :conditions => ['rows.screen_id = ? ', field.screen_id])
    end

    def screen_in_use?(screen_id, scr_cells)
      screen_in_use = false
      
      scr_cells.each do |scr_c|
        screen_ids = cell_screen_ids(scr_c[:value])

        next if screen_ids.empty?
        
        screen_in_use = screen_ids.include?(screen_id)

        break if screen_in_use
      end
      
      screen_in_use
    end
    
    #   CustomFields::SCR.cell_code(Hash)  -> string
    #
    # Get the value for the :code key
    #   CustomFields::SCR.cell_code({:code => 1}) #=> "1"
    #   CustomFields::SCR.cell_code({})           #=> ""
    #   CustomFields::SCR.cell_code(nil)          #=> ""
    def cell_code(cell_value)
      cell_value ||= {}
      
      cell_value[:code].to_s
    end

    #   CustomFields::SCR.cell_parts(Hash)  -> an_array
    #
    # Get the value for the :part key
    #   CustomFields::SCR.cell_parts({:parts => []})  #=> []
    #   CustomFields::SCR.cell_parts({})              #=> []
    #   CustomFields::SCR.cell_parts(nil)             #=> []
    def cell_parts(cell_value)
      cell_value = nil if cell_value.to_s.empty?
      cell_value ||= {}

      cell_value[:parts] ||= []

      cell_value[:parts].each do |p|
        p[:type] = p[:type].to_sym
        p[:screen_id] = p[:screen_id].to_i
        p[:screen_combinded_reference_row_id] = p[:screen_combinded_reference_row_id].to_i
        p[:delimiter] = p[:delimiter].to_s
      end


      cell_value[:parts]
    end

    #   CustomFields::SCR.cell_masks(Hash)  -> an_array
    def cell_masks(cell_value, options = {})
      defaults = {
        :screen => true,
        :group => true,
        :option => true
      }
      options = defaults.merge(options)
      puts "options is #{options.inspect}"
      part_masks(cell_parts(cell_value), options)
    end

            
    #   CustomFields::SCR.cell_parts(Hash, Array)  -> an_array
    #
    # Get the value for the :part key
    #   CustomFields::SCR.cell_parts_by_type({:parts => []}, [:screen,:group])  #=> []
    #   CustomFields::SCR.cell_parts_by_type({})              #=> []
    #   CustomFields::SCR.cell_parts_by_type(nil)             #=> []
    def cell_parts_by_type(cell_value, types)
      types = [types.each{|t| t.to_sym}].flatten.compact
      
      parts = CustomFields::ScreenCombindedReference.cell_parts(cell_value)
      parts.collect{|p| p if types.include?(p[:type])}.compact
    end

    #   CustomFields::SCR.cell_screen_ids(Hash)  -> an_array
    #
    # Get the value for the :screen_id key for :screen type, including sub-groups, all id values will be integer
    #   cell_value = {
    #     :parts => [
    #       {:screen_id => 1, :type => :screen },
    #       {:screen_combinded_reference_row_id => 2, :type => :group },
    #       {:screen_id => 3, :type => :screen }
    #     ]
    #   }
    #   CustomFields::SCR.cell_screen_ids(cell_value)     #=> [1,21,22,3]
    #   CustomFields::SCR.cell_screen_ids({:parts => []}) #=> []
    #   CustomFields::SCR.cell_screen_ids({})             #=> []
    #   CustomFields::SCR.cell_screen_ids(nil)            #=> []
    def cell_screen_ids(cell_value)
      result = []
      cell_part_values(cell_value) do |p|
        case p[:type].to_sym
        when :screen
          result << p[:screen_id].to_i if Screen.exists?(p[:screen_id]) 
        end
      end
      result
    end
    #   CustomFields::SCR.cell_screen_ids(Hash)  -> an_array
    #
    # Get the value for the :screen_id key for :screen type, including sub-groups, all id values will be integer
    #   cell_value = {
    #     :parts => [
    #       {:screen_id => 1, :type => :screen },
    #       {:screen_combinded_reference_row_id => 2, :type => :group },
    #       {:screen_id => 3, :type => :screen }
    #     ]
    #   }
    #   CustomFields::SCR.cell_screen_group_ids(cell_value)     #=> [1,21,22,3]
    #   CustomFields::SCR.cell_screen_group_ids({:parts => []}) #=> []
    #   CustomFields::SCR.cell_screen_group_ids({})             #=> []
    #   CustomFields::SCR.cell_screen_group_ids(nil)            #=> []
    def cell_screen_group_ids(cell_value)
      result = []
      cell_part_values(cell_value) do |p|
        case p[:type].to_sym
        when :screen
          result << p[:screen_id].to_i if Screen.exists?(p[:screen_id])
        when :group
          scr_row = group_scr_row(p)

          result += scr_row.screen_combined_screen_group_ids if scr_row
        end
      end
      result
    end

    #   CustomFields::SCR.cell_screen_group_index(cell_value)     #=> [1,21,22,3]
    #   CustomFields::SCR.cell_screen_group_index({:parts => []}) #=> []
    #   CustomFields::SCR.cell_screen_group_index({})             #=> []
    #   CustomFields::SCR.cell_screen_group_index(nil)            #=> []
    def cell_screen_group_index(cell_value)
      result = nil
      index = 0
      cell_part_values(cell_value) do |p|
        case p[:type].to_sym
        when :group
          result = index
        end
        index = index + 1
      end
      result
    end
     
    #   CustomFields::SCR.cell_screen_ids(Hash)  -> an_array
    #
    # Get the value for the :screen_id key for :screen type, including sub-groups, all id values will be integer
    #   cell_value = {
    #     :parts => [
    #       {:screen_id => 1, :type => :screen },
    #       {:screen_combinded_reference_row_id => 2, :type => :group },
    #       {:screen_id => 3, :type => :screen }
    #     ]
    #   }
    #   CustomFields::SCR.cell_screen_group_descr(cell_value)     #=> [1,21,22,3]
    #   CustomFields::SCR.cell_screen_group_descr({:parts => []}) #=> []
    #   CustomFields::SCR.cell_screen_group_descr({})             #=> []
    #   CustomFields::SCR.cell_screen_group_descr(nil)            #=> []
    def cell_screen_group_descr(cell_value)
      result = []
      cell_part_values(cell_value) do |p|
        case p[:type].to_sym
        when :screen
          result << Screen.find(p[:screen_id].to_i).label_descr if Screen.exists?(p[:screen_id])
        when :group
          scr_row = group_scr_row(p)

          result << scr_row.description if scr_row
        end
      end
      result
    end
    #   CustomFields::SCR.cell_option_screen_ids(Hash)  -> an_array
    #
    # Get the value for the :screen_id key for :option type, including sub-groups, all id values will be integer
    #   cell_value = {
    #     :parts => [
    #       {:screen_id => 1, :type => :option },
    #       {:screen_combinded_reference_row_id => 2, :type => :group },
    #       {:screen_id => 3, :type => :option }
    #     ]
    #   }
    #   CustomFields::SCR.cell_option_screen_ids(cell_value)     #=> [1,21,22,3]
    #   CustomFields::SCR.cell_option_screen_ids({:parts => []}) #=> []
    #   CustomFields::SCR.cell_option_screen_ids({})             #=> []
    #   CustomFields::SCR.cell_option_screen_ids(nil)            #=> []
    def cell_option_screen_ids(cell_value)
      cell_part_values(cell_value) do |p|
        case p[:type].to_sym
        when :group
          scr_row = group_scr_row(p)

          scr_row.screen_combined_option_screen_ids if scr_row
        when :option
          p[:screen_id].to_i if Screen.exists?(p[:screen_id])
        end
      end
    end
    #   CustomFields::SCR.cell_option_screen_ids(Hash)  -> an_array
    #
    # Get the value for the :screen_id key for :option type, including sub-groups, all id values will be integer
    #   cell_value = {
    #     :parts => [
    #       {:screen_id => 1, :type => :option },
    #       {:screen_combinded_reference_row_id => 2, :type => :group },
    #       {:screen_id => 3, :type => :option }
    #     ]
    #   }
    #   CustomFields::SCR.screen_combined_reference_row_id(cell_value)     #=> [1,21,22,3]
    #   CustomFields::SCR.screen_combined_reference_row_id({:parts => []}) #=> []
    #   CustomFields::SCR.screen_combined_reference_row_id({})             #=> []
    #   CustomFields::SCR.screen_combined_reference_row_id(nil)            #=> []
    def screen_combined_reference_row_id(cell_value)
      cell_part_values(cell_value) do |p|
        case p[:type].to_sym
        when :group
          p[:screen_combinded_reference_row_id].to_i
        end
      end.last
    end

    def scr_option_rows(scr_row)
      scr_cf_refs = scr_row.screen.references_custom_fields
      scr_field = scr_row.screen.screen_combined_reference_field
      option_screen_ids = CustomFields::ScreenCombindedReference.cell_option_screen_ids(scr_row.cell(scr_field.custom_field_id).value)
      
      ht_cf_value = {}
      scr_cf_refs.each do |cf|
        ht_cf_value[cf.id.to_s] = scr_row.cell(cf.id).nil? ? '' : CustomFields::Reference.cell_ref_row_id(scr_row.cell(cf.id).value)
      end
      
      option_rows = option_screen_ids.collect do |s_id|
        screen = Screen.find(s_id.to_i)
        filter_cf = screen.filter_custom_fields(scr_cf_refs)
        if filter_cf.empty?
          screen.rows
        else
          options = Row.filter_by_custom_fields(screen.id, ht_cf_value, 'search', nil)
          Row.find(:all, :conditions => ['id in (?)', options[:filtered_row_ids]])
        end
      end.flatten
      
      option_rows.sort{|x,y| x.description <=> y.description }
    end

    def screen_combined_reference_rows(scr_row)
      result = []
      
      scr_cf_refs = scr_row.screen.references_custom_fields
      ht_cf_value = {}
      scr_cf_refs.each do |cf|
        ref_row_id = CustomFields::Reference.cell_ref_row_id(scr_row.cell(cf.id))
        ht_cf_value[cf.id.to_s] = { :row_id => ref_row_id } unless ref_row_id == 0
      end

      scr_cell_values = scr_row.screen_combined_cell.value
      parts = CustomFields::ScreenCombindedReference.cell_parts(scr_cell_values)
      
      result = parts.collect do |p|
        case p[:type]
        when :screen
          if p[:screen_id].to_i > 0
            screen = Screen.find(p[:screen_id])

            filter_cf = screen.filter_custom_fields(scr_cf_refs)
            if filter_cf == []
              { :screen => screen, :rows => screen.rows }
            else
              options = Row.filter_by_custom_fields(screen.id, ht_cf_value, 'search', true)
              filtered_row_ids = options[:filtered_row_ids]
              filtered_rows = Row.find(:all, :conditions => { :rows => { :id => filtered_row_ids } } )
              { :screen => screen, :rows => filtered_rows }
            end
          end
        when :group
          {}
        end
      end.compact
      
      result
    end

    #   CustomFields::SCR.is_screen_used_as_multiply_count?(Hash, int)  -> true/false
    #
    # Check if the specified screen is assigned to be a group multiply counter.
    #   cell_value = {
    #     :parts => [
    #       {:screen_id => 1, :type => :screen },
    #       {:screen_id => 2, :type => :screen },
    #       {:screen_id => 2, :type => :group },
    #       {:screen_id => 3, :type => :screen }
    #     ]
    #   }
    #   CustomFields::SCR.is_screen_used_as_multiply_count?(cell_value, 1)      #=> false
    #   CustomFields::SCR.is_screen_used_as_multiply_count?(cell_value, 2)      #=> true
    #   CustomFields::SCR.is_screen_used_as_multiply_count?({:parts => []}, 3)  #=> false
    #   CustomFields::SCR.is_screen_used_as_multiply_count?({}, 1)              #=> false
    #   CustomFields::SCR.is_screen_used_as_multiply_count?(nil, 2)             #=> false
    def is_screen_used_as_multiply_count?(cell_value, screen_id)
      group_parts = cell_part_values(cell_value) do |p|
        p[:screen_id] if p[:type].to_sym == :group
      end.select{|s_id| s_id.to_i == screen_id.to_i}
      
      screen_id > 0 && !group_parts.empty?
    end

    def cell_multiplier_index(cell_value)
      parts = cell_parts(cell_value)
      parts.inject(nil){|i, p| is_screen_used_as_multiply_count?(cell_value, p[:screen_id]) && p[:type] == :screen ? parts.index(p) : i } || -1
    end
    
    #   CustomFields::SCR.is_screen_used_as_multiply_count?(Hash, int)  -> true/false
    #
    # Check if the specified screen is assigned to be a group multiply counter.
    #   cell_value = {
    #     :parts => [
    #       {:screen_id => 1, :type => :screen },
    #       {:screen_id => 2, :type => :screen },
    #       {:screen_id => 2, :type => :group },
    #       {:screen_id => 3, :type => :screen }
    #     ]
    #   }
    #   CustomFields::SCR.group_row_id(cell_value)      #=> 22
    #   CustomFields::SCR.group_row_id(cell_value)      #=> 22
    #   CustomFields::SCR.group_row_id({:parts => []})  #=> 22
    #   CustomFields::SCR.group_row_id({})              #=> 33
    #   CustomFields::SCR.group_row_id(nil)             #=> 44
    def group_row_id(cell_value)
      group_parts = cell_part_values(cell_value) do |p|
        p[:screen_combinded_reference_row_id].to_i if p[:type].to_sym == :group
      end

      row_id = group_parts.first unless group_parts.nil?
      
      row_id.to_i
    end

    #   CustomFields::SCR.is_screen_used_as_multiply_count?(Hash, int)  -> true/false
    #
    # Check if the specified screen is assigned to be a group multiply counter.
    #   cell_value = {
    #     :parts => [
    #       {:screen_id => 1, :type => :screen },
    #       {:screen_id => 2, :type => :screen },
    #       {:screen_id => 2, :type => :group },
    #       {:screen_id => 3, :type => :screen }
    #     ]
    #   }
    #   CustomFields::SCR.screen_used_as_multiply_count_index(cell_value)             #=> 1
    def screen_used_as_multiply_count_index(cell_value)
      screen_id_used_as_multiply_count = cell_part_values(cell_value) do |p|
        p[:screen_id] if p[:type].to_sym == :group
      end.select{|s_id| s_id.to_i}

      checking = true
      indexes = 0
      cell_part_values(cell_value) do |p|
        indexes += 1 if checking
        checking = false if p[:screen_id].to_i == screen_id_used_as_multiply_count.first
      end

      indexes - 1
    end

    #   CustomFields::SCR.is_group?(calue, int)  -> true/false
    def is_group?(cell_value, screen_id)
      group = cell_part_values(cell_value) do |p|
        true if p[:type].to_sym == :group && p[:screen_id].to_i == screen_id.to_i
      end.compact!

      group.first unless group.nil?
    end

    #   CustomFields::SCR.group_index(value)  -> index
    def group_index(cell_value)
      parts = CustomFields::ScreenCombindedReference.cell_parts(cell_value)
      parts.inject(nil){|i, p| (p[:type] == :group) ? parts.index(p) : i }
    end
    #   CustomFields::SCR.parse(model_serie_code, data_format, screen_combinded_reference_rows) -> Hash
    # Parse the specified data_format, and build the hash structure, to represent
    # the SCR settings
    #   #~ Prepreation for building the env data
    #   /*
    #   screens = %w(
    #   S_1_NAME
    #   S_2_NAME
    #   S_7_NAME
    #   S_8_NAME
    #   S_9_NAME
    #   S_10_NAME
    #   S_11_NAME
    #   S_12_NAME
    #   S_13_NAME
    #   ).collect {|s_name| Screen.find_by_name(s_name) || Screen.create(:name => s_name) }
    #
    #   master_screen = Screen.find_by_name('ScreenMaster_Model')
    #   screens.each do |s|
    #     s.screen = master_screen
    #     s.label = Label.descr_by_name('G_Screen')
    #     s.controller = :screens
    #     s.action = :show
    #     s.save
    #   end
    #   */
    #
    #   #~ a SCR row with code 'SCR_99_CODE' is required
    #
    #   scr_custom_field = CustomFields::ScreenCombindedReference.find(:first)
    #   scr_rows = CustomFields::SCR.find_all_rows(scr_custom_field)
    #
    #   model_serie_code = 'S_0_NAME'
    #   data_format = '-[S_1_NAME]-[S_2_NAME][SCR_99_CODE]<S_2_NAME>-[S_7_NAME]-[S_8_NAME][S_9_NAME][S_10_NAME]-[S_11_NAME](-[S_12_NAME]-[S_13_NAME])'
    #
    #   CustomFields::SCR.parse(model_serie_code, data_format, scr_rows)  #=>
    #   {
    #     :code => "S_0_NAME",
    #     :parts => [
    #       {
    #         :delimiter => "-",
    #         :type => :screen/:group/:option,
    #         :screen_id => 1,
    #         :screen_combinded_reference_row_id => 99
    #       }
    #     ]
    #   }
    #
    #   screens.each {|s| s.destroy }
    def parse(model_serie_code, data_format, screen_combinded_reference_rows = {}, scr_cf = nil)
      value = {
        :code => model_serie_code.to_s.strip,
        :parts => parse_parts(data_format.to_s.strip, screen_combinded_reference_rows, scr_cf)
      }

      value[:error_messages] = []
      value[:error_messages] << 'Invalid model_serie_code value' if value[:code].empty?
      value[:error_messages] << 'Invalid data_format value' unless is_valid?(data_format)
      value[:error_messages] += value[:parts].collect{|p| p[:error_messages] }.compact

      value.delete(:error_messages) if value[:error_messages].empty?
      
      value
    end

    def is_valid?(data_format)
      valid_over_all = !(data_format =~ scr_reqexp).nil?

      if data_format =~ group_reqexp
        multiply_screen_name = data_format.
          gsub(option_reqexp,'').
          gsub(screen_reqexp,'').
          gsub(/[<>]/,'')

        valid_group = !(data_format =~ screen_reqexp(multiply_screen_name) ).nil? unless multiply_screen_name =~ /SCR_CODE/
      end
      
      valid_over_all && (valid_group.nil? || valid_group)
    end

    def find_all_rows(scr_custom_field, related_from_custom_fields = {})
      result = {}

      dup_codes = {}

      scr_custom_field.fields.each do |f|
        rows = Row.find_by_reference_custom_fields(f.screen_id, related_from_custom_fields)
        rows.each do |r|
          code = r.screen_combined_code.to_s

          next if code.empty?

          if result[code].nil?
            result[code] = r
            result[r.id] = r
          else
            dup_codes[f.screen.name] ||= []
            dup_codes[f.screen.name] << code
            dup_codes[f.screen.name].uniq!
          end
        end
      end

      raise "Duplicate value in the following screens...<pre>#{dup_codes.to_yaml}</pre>" unless dup_codes.empty?

      result
    end

    private

    def invalid_screen_name_pattern
      "[^\\w.]"
    end

    def invalid_screen_name_reqexp
      @@invalid_screen_name_reqexp ||= /#{invalid_screen_name_pattern}/
    end
    
    def valid_screen_name_pattern
      "#{invalid_screen_name_pattern}+".gsub('^', '')
    end

    def valid_screen_name_reqexp
      @@valid_screen_name_reqexp ||= /#{valid_screen_name_pattern}/
    end

    def delimiter_pattern
      "(#{CustomFields::ScreenCombindedReference.delimiter.join('|')})?"
    end
    
    def screen_pattern(screen_name = nil)
      screen_name ||= valid_screen_name_pattern
      "#{delimiter_pattern}\\[#{screen_name}\\]"
    end

    def screen_reqexp(screen_name = nil)
      @@screen_reqexp ||= {}
      
      @@screen_reqexp[screen_name] ||= /#{screen_pattern(screen_name)}/
    end

    def group_pattern
      "<#{valid_screen_name_pattern}>"
    end

    def group_reqexp
      @@group_reqexp ||= /#{group_pattern}/
    end

    def option_pattern
      "\\((#{screen_pattern})+\\)"
    end

    def option_reqexp
      @@option_reqexp ||= /#{option_pattern}/
    end

    def part_pattern
      "#{screen_pattern}(#{group_pattern})?"
    end

    def part_reqexp
      @@part_reqexp ||= /#{part_pattern}/
    end

    def scr_pattern
      "^(#{screen_pattern})+(#{group_pattern})?(#{screen_pattern})*(#{option_pattern})?$"
    end

    def scr_reqexp
      @@scr_reqexp ||= /#{scr_pattern}/
    end

    def cell_part_values(cell_value)
      parts = cell_parts(cell_value)
      parts.collect do |p|
        yield p
      end.flatten.compact
    end
    
    def group_scr_row(part)
      scr_row_id = part[:screen_combinded_reference_row_id].to_i

      Row.find(scr_row_id) if scr_row_id > 0
    end
    
    def parse_parts(data_format, screen_combinded_reference_rows = {}, scr_cf = nil)
      mains_and_options = data_format.to_s.gsub(/(#{option_pattern})/, '|\1').split('|').select{|e| !e.empty?}
      
      main_parts = mains_and_options.first
      option_parts = mains_and_options.last.gsub(/[()]/, '') if mains_and_options.length > 1

      main_parts = parse_part(main_parts).collect{|p| part_hash(p, false, screen_combinded_reference_rows, scr_cf) }
      option_parts = parse_part(option_parts.to_s).collect{|p| part_hash(p, true, screen_combinded_reference_rows, scr_cf) }
      
      main_parts + option_parts
    end
    
    def parse_part(part_format)
      part_format.to_s.gsub(/(#{part_pattern})/, '|\1').split('|').select{|e| !e.empty?}
    end
    
    def part_hash(part, o, screen_combinded_reference_rows = {}, scr_cf = nil)
      delimiter = part =~ /^.\[/ ? part.split(/\[/).first : ''
      type = o ? :option : part =~ /</ ? :group : :screen

      screens = part.split(/</).collect{|s| s.to_s.gsub(/#{invalid_screen_name_pattern}/, '')}

      first_screen_name = screens.first.to_s.gsub(/[^a-zA-Z0-9]/, '_').gsub(/[_]+/, '_')
      last_screen_name = screens.last.to_s.gsub(/[^a-zA-Z0-9]/, '_').gsub(/[_]+/, '_') if screens.size > 1

      screen_keys = {}

      if type == :group
        screen_combinded_reference_row = screen_combinded_reference_rows[screens.first]
        
        if screen_combinded_reference_row.nil? == 0
          screen_keys.update({ :error_messages => "Missign ScreenCombindedReference Row name '#{first_screen_name}'" } )
        else
          screen_keys.update({ :screen_combinded_reference_row_id => screen_combinded_reference_row.id } )
        end

        screen_name = last_screen_name
      else
        screen_name = first_screen_name
      end
      
      if screen_name =~ /SCR_CODE/
        screen_keys.update({
            :screen_id => -1
          })
      else
        screen = Screen.find_by_name(screen_name)
        if screen.nil?
          screen_keys.update({
              :error_messages => "Missign Screen name '#{screen_name}'"
            })
        elsif scr_cf && !(scr_cf.screen_ids+scr_cf.option_screen_ids).include?(screen.id)
          screen_keys.update({
              :error_messages => "Screen name '#{screen_name}' not allowed to be used in '#{scr_cf.label_descr}'"
            })
        else
          screen_keys.update({
              :screen_id => screen.id
            })
        end
      end
      
      {
        :delimiter => delimiter,
        :type => type
      }.update(screen_keys)
    end
    
    def part_masks(parts, options = {})
      parts.collect{|p|
        next if !options[p[:type].to_sym]

        part = case p[:type]
        when :screen, :option
          "[#{p[:screen_id]}]"
        when :group
          group_scr_row = group_scr_row(p)
          group_parts = cell_parts(group_scr_row.screen_combined_cell.value)
          "(#{part_masks(group_parts, include_options)}){#{p[:screen_id]}}"
        end

        "#{p[:delimiter]}#{part}"
      }.compact
    end
  end #end class << self

  def search_value?(value, filter)
    return true if filter.nil?
    
    value.to_s.downcase.include?(filter.to_s.downcase)
  end
  
  def description
    'Screen Combinded Reference'
  end

  def screen_ids
    self[:value][:screen_ids] ||= []
    @screen_ids ||= self[:value][:screen_ids].collect{|s_id| s_id.to_i if Screen.exists?(s_id) }.compact
  end

  def screens
    screen_ids.collect{|s_id| Screen.find(s_id) if Screen.exists?(s_id) }.compact
  end

  def option_screen_ids
    self[:value][:option_screen_ids] ||= []
    @option_screen_ids ||= self[:value][:option_screen_ids].collect{|s_id| s_id.to_i if Screen.exists?(s_id) }.compact
  end

  def option_screens
    option_screen_ids.collect{|s_id| Screen.find(s_id)}
  end

  def text(value)
    value_screen_ids = CustomFields::ScreenCombindedReference.cell_screen_ids(value)
    value_screens = Screen.find(:all, :conditions => { :screens => { :id => [value_screen_ids].flatten } })
    
    value_option_screen_ids = CustomFields::ScreenCombindedReference.cell_option_screen_ids(value)
    value_option_screens = Screen.find(:all, :conditions => { :screens => { :id => [value_option_screen_ids].flatten } })
    
    codes = value[:code]
    codes += " main screens: " + value_screens.collect{|s| "[#{s.name}]"}.join("-")
    codes += " option screens: " + value_option_screens.collect{|s| "[#{s.name}]"}.join("-")
  end

  def html(value)
    value[:code]
  end

  def parse(value, options={})
    defaults = {
      :scr_rows => {}
    }
    options = defaults.merge(options)
    
    parts = value.split(/:/)

    model_serie_code = parts.first
    data_format = parts[1...parts.size].join(':')

    scr_value = CustomFields::ScreenCombindedReference.parse(model_serie_code, data_format, options[:scr_rows], self)

    raise scr_value[:error_messages].inspect if scr_value.has_key?(:error_messages)

    scr_value
  end

  def validate_value(cell_value, options = {})
    #~ ToDo: Remove incomplete part configurations
    cell_value[:parts] = cell_value[:parts].collect{|p| p if p['type'] != '' && p['screen_id'] != ''}.compact

    cell_value
  end

  def is_empty?(cell_value)
    is_empty ||= CustomFields::ScreenCombindedReference.cell_code(cell_value).empty?
  end
end

# Short alias for CustomFields::ScreenCombindedReference
class CustomFields::SCR < CustomFields::ScreenCombindedReference
  # Prevent this class from being created
  private_class_method :new
end

#    content = retrieve_screen_combinded_reference_result(@gen_rows[row.id][cf.id])

