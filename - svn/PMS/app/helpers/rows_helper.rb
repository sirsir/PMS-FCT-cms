module RowsHelper
	def valuecheck(row, field)
    actual_row = Field.row_by_field(field, row)
    cell = actual_row.cell(field.custom_field_id) unless actual_row.nil?
		result = cell.value if cell
		result = (result.to_s == '') ? '&nbsp;' : result
	end
	
	def retrieve_nonmulti_result(all_values)
		cell_values = []
		if all_values != '&nbsp;'
			all_values.each do |r|
				row = Row.find(r.to_i)
        cell_values << row.description
			end
		else
			cell_values << all_values
		end
		return cell_values.join(',')
	end
	
	def retrieve_multi_result(all_values)
		cell_values = []
		if all_values != '&nbsp;'
			all_values.each do |r|
				cell_values << Caption.find_by_label_id(r).name.to_s 
			end
		else
			cell_values << all_values
		end	
		return cell_values.join(',')
	end
	
	def retrieve_checkbox_result(checked_value,all_values,cell,g_other)
    cell_values = ''
    multi_checkbox = (all_values['label_ids'].size > 1)
    all_values['label_ids'].each do |all_value|
      checked_str = ''
      other_str = ''
      chk_name = multi_checkbox ? (Label.find(all_value)).descr : ''
      if checked_value != '&nbsp;'
        checked_value.each_key do |k_checked|
          if k_checked == all_value
            checked_str = 'checked'
            if (cell != nil) && (k_checked == g_other.id.to_s)
              other_str = cell.value[(g_other.id).to_s]
            end
          end
        end
      end
      cell_values << "<input type=\"checkbox\"#{checked_str} disabled >#{chk_name}#{other_str}<br>"
    end
    return cell_values
	end

  def retrieve_radiobox_result(all_values)
    label = '&nbsp;'
    text = ''
    cell_values = ''
    if all_values != '&nbsp;'
      all_values.each do |r|
        if r[0] == 'label'
          label =  Caption.find_by_label_id(r[1]).name.to_s
        else
          text = ' (' + r[1].to_s + ')'
        end
      end
    end
    cell_values = label + text
    return cell_values
  end

  def html_issue_tracking_desc
    html = ''
    html << image_tag('cancelled.gif') + ' Cancel '
    html << image_tag('completed.gif') + ' Complete '
    html << image_tag('delayed.gif') + ' Delay '
    html << image_tag('dued.gif') + ' Due '
    html << image_tag('rescheduled.gif') + ' Re-Schedule '
    html << image_tag('scheduled.gif') + ' Schedule'
  end

  def retrieve_cell_cf(cell_id, cf_id)
    cf = CustomField.find(cf_id)
    cell_value = Cell.find(:first, :conditions => ['row_id = ? and field_id = ?', cell_id, cf_id])
    unless cell_value.nil?
      if cell_value.value == ''
        return ''
      else
        return cell_value.value
      end
    end
  end

  def retrieve_screen_combinded_reference_result(all_values)
    cell_values = ''
    if all_values != ''
      cell_values =  all_values[:code]
    end
    return cell_values
  end

  def retrieve_option_combinded_reference_result(all_values)
    cell_values = ''
    if all_values != ''
      cell_values =  all_values[:code]
    end
    return cell_values
  end
  
  def full_text_toogler_tag(cell_id, value, row_id = nil)
    if value.to_s =~ /error_message/ || !value.is_a?(String)
      short_remark = value
    else
      full_remark = value.to_s.empty? ? '&nbsp;' : value
      short_remark = full_remark[0..29]
      
      opened_html_tag_position = short_remark =~ /<[^>]*$/
      short_remark = full_remark[0..opened_html_tag_position-1] if opened_html_tag_position
        
      long_remark_id = "#{cell_id}_long"
      short_remark_id = "#{cell_id}_short"

      if full_remark != short_remark
        short_btn = "#{short_remark}&hellip;&nbsp;&raquo;"
        long_btn = "#{full_remark}&nbsp;&laquo;"
        short_remark = <<HTML_TAG
<span id='#{short_remark_id}' title='Show' onclick='fncSwitchRemark("#{long_remark_id}", "#{short_remark_id}", "#{row_id}")' style='cursor: e-resize;'               >#{short_btn}</span>
HTML_TAG

        long_remark = <<HTML_TAG
<span id='#{long_remark_id}' title='Hide' onclick='fncSwitchRemark("#{short_remark_id}", "#{long_remark_id}", "#{row_id}")' style='cursor: e-resize; display: none;'>#{long_btn}</span>
HTML_TAG
      end
    end

  <<HTML_TAG
#{short_remark.to_s.strip}#{long_remark.to_s.strip}
HTML_TAG
  end
  
  def get_print_rows_per_page(total_rows, options = {})
    defaults = {
      :single_page_size => 20,
      :first_page_size => 40,
      :last_page_size => 40,
      :other_page_size => 60
    }

    options = defaults.merge(options)
    

    rows_per_page = []

    if total_rows <= options[:single_page_size]
      rows_per_page << options[:single_page_size]
    else
      rows_per_page << options[:first_page_size]

      if total_rows > (options[:first_page_size] + options[:last_page_size])
        cnt = (total_rows - options[:first_page_size] - options[:last_page_size]) / options[:other_page_size] + 1
        rows_per_page += [options[:other_page_size]] * cnt
      end

      rows_per_page << options[:last_page_size]
    end

    rows_per_page
  end

  def address_text(options = {})
    defaults = {
      :no => '',
      :moo => '',
      :soi => '',
      :road => '',
      :sub_dist => '',
      :dist => '',
      :province => '',
      :postal => '',
      :tel => '',
      :fax => ''
    }

    options = defaults.merge(options)

    addresses = {}
    addresses[:address_1] = <<ADDRESS
#{options[:no]} #{'Moo' unless options[:moo].empty?} #{options[:moo]}
#{'Soi' unless options[:soi].empty?} #{options[:soi]} #{options[:road]} #{'Rd.' unless options[:road].empty?},
#{options[:sub_dist]}#{',' unless options[:sub_dist].empty?} #{options[:dist]}#{',' unless options[:dist].empty?}
ADDRESS
    addresses[:address_2] = "#{options[:province]} #{options[:postal]} Thailand"
    addresses[:tel] = <<ADDRESS
#{'Tel:' unless options[:tel].empty? } #{options[:tel]} #{'Fax:' unless options[:fax].empty? } #{options[:fax]}
ADDRESS
    
    addresses
  end
  
  def page_break_after_tag
    <<HTML_TAG
<div style="page-break-after: always; height:1px;">&nbsp;</div>
HTML_TAG
  end

  def clr_index(index)
    index % (clr_base_color1 * clr_base_color2 * clr_base_color3)
  end

  def background_color(index, options = {})
    defaults = {
      :hex => false,
      :full_btye => true
    }
    options = defaults.merge(options)

    #~ 128, 138, 148, 158, 168, 178, 188, 198, 208, 218, 228
    c1 = (clr_base_color1 - (index % clr_base_color1)) * 16 + 64
    #~ 0, 25, 50, 75, 100, 125, 150
    c2 = index % clr_base_color2 * 32
    #~ 0, 64, 128, 192, 255
    c3 = [index % clr_base_color3 * 64, 255].min
    #~ 11 x 7 x 5 = 385 Colors

    case index % 6
    when 0
      red, green, blue = c1, c2, c3
    when 1
      red, green, blue = c3, c1, c2
    when 2
      red, green, blue = c2, c3, c1
    when 3
      red, green, blue = c1, c3, c2
    when 4
      red, green, blue = c2, c1, c3
    else
      red, green, blue = c3, c2, c1
    end

    return red, green, blue
  end

  def foreground_color(red, green, blue)
    #~ [red, green, blue].select{|c| c < 128 }.size > 1 ? 'white' : 'black'
    green < 192 ? 'white' : 'black'
  end
  
  private
  
  def clr_base_color1
    11
  end
  
  def clr_base_color2
    7
  end
  
  def clr_base_color3
    5
  end
end