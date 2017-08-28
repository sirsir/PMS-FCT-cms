class Fields::DetailInfo < Field

  def description
    'Display child\'s or related reference information'
  end

  def detail_screen_id
    value['dependency_screen_id'].to_i
  end

  def detail_screen
    Screen.find(detail_screen_id) if Screen.exists?(detail_screen_id)
  end

  def get_detail_screen_value(screen,row)
    
    dependency_screen_id = self.value['dependency_screen_id']
    detail_screen_field_ids = (self.value['detail_screen_field_ids'] || []).select{|f_id| f_id.to_i > 0}
    dependency_screen = Screen.find(dependency_screen_id)
    
    # finding field that use to relate between screen and dependency screen

    relation_custom_fields = dependency_screen.fields.collect do |f|
      case f
      when Fields::Data then
        case f.custom_field
        when CustomFields::Reference then
          f.custom_field if f.custom_field.screen_id == screen.id
        end
      end
    end.compact

    # get relation type
    case dependency_screen
    when RevisionScreen
      relation_type = :header_revision if dependency_screen.header_screen.id == screen.id
    when DetailScreen
      case self.screen
      when HeaderScreen
        relation_type = :header_detail if dependency_screen.revision_screen.header_screen.id == screen.id
      when RevisionScreen
        relation_type = :revision_detail if dependency_screen.revision_screen.id == screen.id
      end
    end

    relation_type ||= :custom_fields

    #finding result
    detail_rows = dependency_screen.rows.select do |r|
      case relation_type
      when :header_revision
        r.header_row.id == row.id
      when :header_detail
        r.revision_row.header_row.id == row.id
      when :revision_detail
        r.revision_row.id == row.id
      when :custom_fields
        if dependency_screen.control_revision? && (r != r.header_row.latest_revision)
          false
        else
          relation_custom_fields.any? do |cf|
            ref_cell = r.cell(cf.id)

            ref_cell && CustomFields::Reference.cell_ref_row_id(ref_cell.value) == row.id
          end
        end
      end
    end

    #Merging result into one string
    detail_screen_fields = [Field.find(detail_screen_field_ids)].flatten
    detail_rows.collect{|r|
      detail_values = detail_screen_fields.collect do |f|
        case f
        when Fields::Data
          actual_row = Field.row_by_field(f, r)
          cell = actual_row.cell(f.custom_field_id) unless actual_row.nil?
          cell.to_text if cell
        else
          f.evaluate_value(r)
        end
      end
      
      detail_values = detail_values.join(' - ') unless detail_values.first.is_a?(Array)

      detail_values
    }.flatten.select{|t| !t.empty? }.uniq.sort
  end

  def evaluate_value(row)
    get_detail_screen_value(row.screen, row)
  end

  # ToDo: Find reference to Fields::DetailInfo.new.valuecheck(row, custom_field)
  # if non exist, remove the function
  def valuecheck(row, custom_field) # editing recieved parameter from field to custom field
		result = (row.cell(custom_field.id).nil?) ? '&nbsp;' : row.cell(custom_field.id).value
		result = (result == '') ? '&nbsp;' : result
	end


  # ToDo: Find reference to Fields::DetailInfo.new.retrieve_nonmulti_result(all_values)
  # if non exist, remove the function
	def retrieve_nonmulti_result(all_values)
		cell_values = []
		if all_values != '&nbsp;'
			all_values.each do |r|
				row = Row.find(r.to_i)
        cell_values << row.description
				#cell_values << row.cell(name_custom_field.id).value
			end
		else
			cell_values << all_values
		end

		#return value
		{:cell_values => cell_values}
	end
  
end

