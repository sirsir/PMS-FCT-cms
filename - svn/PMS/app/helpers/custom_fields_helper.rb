module CustomFieldsHelper
  def field_for_list(name, cell, options={})
  #   1. if Reference
  #   2. cell.value => ref_row_id
  #     3. ref_row_id => ref_row
  # *   4. ref_row.cells => [cell_of_name, cell_of_code, cell_of_date,...]
  #   5. cell.feild => ref_custom_field
  # *   6. ref_custom_field.custom_field_ids => [cf_id_of_code, cf_id_of_name]
  #   7.  4. x 6.
  #     a = [..., ...]
  #     a.join!(" ")
  end

  # options
  #   :screen_id        :
  #   :count            :
  #   :fields_per_line  :
  def field_for_search(field_or_custom_field, options = {})
    case field_or_custom_field
    when Field
      field = field_or_custom_field
      case field
      when Fields::Data then
        result = field_for_search(field.custom_field, options.update(:field => field ))
      else
        result = "<span class=implementation_missing>Please define how to display the search control(s) for the '#{field.class.to_s}' in #{ __FILE__.gsub(RAILS_ROOT, '')}</span>"
        result = '' unless RAILS_ENV =~ /development/
      end 
    when CustomField
      custom_field = field_or_custom_field
      field = options[:field]

      defaults = {
        :name => :custom_field,
        :screen_id => nil,
        :count => 1,
        :fields_per_line => 1,
        :value => nil,
        :read_only => false,
        :range => true,
        :screen_index => nil
      }

      options = defaults.merge(options)

      case options[:name]
      when :field
        input_name = 'fields'
        input_name << "[#{options[:screen_id]}]" if options[:screen_id]
        input_name << "[#{field.id}]"
      when :custom_field
        input_name = 'custom_fields'
        input_name << "[#{options[:screen_id]}]" if options[:screen_id]
        input_name << "[#{custom_field.id}]"
      when :field_filter
        input_name = 'field_filter'
        input_name << "[#{options[:screen_index]}][#{field.id}][value]"
      end

      input_id = sanitize_to_id(input_name)

      case custom_field
      when CustomFields::CheckBox then
        result = ''
        custom_value = get_all_and_selected_value(custom_field,nil,nil)
        if options[:read_only] then 
          cell = Cell.new(:field_id => custom_field.id, :value => options[:value])
          result = cell.to_html
        else
          assigned_values = CustomFields::CheckBox.cell_label_ids(options[:value])
          result << hidden_field_tag("#{input_name}[-1]", false)
          if field.custom_field.single_value?

            labels = [
              [field.custom_field.true_label.descr, '0'],
              [field.custom_field.false_label.descr, '-1']
            ]

            result << select_tag("#{input_name}[label_id]", '<option></option>' +
                options_for_select(labels))

          else
            not_check_assigned_values = CustomFields::CheckBox.cell_not_check(options[:value])
            custom_value[0].each_with_index do |c,count|
              result << check_box_tag("#{input_name}[#{c.id}]", true, assigned_values[c.id]) + c.descr
              result << '<br>' if count % 2 == 1
            end
            result << check_box_tag("#{input_name}[Not_Check]", true, not_check_assigned_values) + 'Not Check'
          end
        end

        result

      when CustomFields::ComboBox then
        result = ''
        options[:value] ||= {}

        if options[:read_only] then 
          options[:value].delete('-1')
          options[:value].each do |k, v|
            result << check_box_image_tag(v)
            result << Label.find(k.to_i).descr
          end
        else
          custom_value = get_all_and_selected_value(custom_field,nil,nil)


          result << hidden_field_tag("#{input_name}[-1]", false)
          custom_value[0].each_with_index do |c,count|
            result << check_box_tag("#{input_name}[#{c.id}]", true, CustomFields::CheckBox.true_or_false?(options[:value][c.id.to_s])) + c.descr.to_s
            result << '<br>' if count % 2 == 1
          end
        end
        result

      when CustomFields::DateTimeField, CustomFields::DateTimeRange then
        options[:value] ||= {}
        options[:value][:from] ||= Date.null_date
        options[:value][:to] ||= Date.null_date
        if options[:read_only] then
          if options[:value][:from] == Date.null_date && options[:value][:to] == Date.null_date
            result = ''
          else
            result = [:from, :to].collect do |a| 
              if options[:value][a] == Date.null_date
                result = '&hellip;'
              else
                cell = Cell.new(:field_id => custom_field.id, :value => options[:value][a])
                result = cell.to_html
              end
            end.join(' ~ ')
          end
        else
          result = field_date_search_with_status(input_name,field ,options[:screen_id],options[:name], options[:value][:from],options[:value][:to],options[:value][:status],options[:value][:format], options[:range])
        end
        result

      when CustomFields::ListBox then
        result = '...'

      when CustomFields::RadioButton then
        if options[:read_only] then 
          cell = Cell.new(:field_id => custom_field.id, :value => options[:value])
          result = cell.to_html
        else
          assigned_value = CustomFields::RadioButton.cell_label_ids(options[:value])
          custom_value = get_all_and_selected_value(custom_field, nil, nil)
          result = ''
          custom_value[0].each_with_index do |c,count|
            result << check_box_tag("#{input_name}[#{c.id}]", true, assigned_value.include?(c.id.to_s)) + c.descr.to_s
            result << '<br>' if count % 2 == 1
          end
        end

        result

      when CustomFields::Reference then
        reference_row_id = CustomFields::Reference.cell_ref_row_id(options[:value])
        reference_row = reference_row_id == 0 ? nil : Row.find(reference_row_id)
        if options[:read_only] then
          result = reference_row.nil? ? '-' : reference_row.description
        else
          unless custom_field.searchable_text?
            cell = Cell.new(:field_id=>custom_field.id)
            related_from = CustomFields::Reference.field_related_from(field.value)
            combo_box_options = cell.select_value_options(reference_row_id == 0 ? 0 : related_from)
          else
            combo_box_options = { :all_options => [] }
          end
          
          if custom_field.searchable_text? || combo_box_options[:all_options].size > 50
            reference_row_descr = reference_row.nil?  ? '' : reference_row.description
            operation_url_option = url_for(:controller => 'rows',
              :action=>'quick_search',
              :id=>0,
              :screen_id=>custom_field.screen_id,
              :text=>'JAVASCRIPT_VAR_TEXT',
              :input_id=>'JAVASCRIPT_VAR_ID',
              :result_row_id =>"#{input_id}_row_id",
              :field_id => field.id)

            onkeyup = <<JAVASCRIPT
fncQuickSearch("_suggest_disp_#{input_id}","#{operation_url_option}", this, "#{input_id}_row_id");
JAVASCRIPT

            onblur = <<JAVASCRIPT
fncResetQuickSearchText("_suggest_disp_#{input_id}", this, "#{input_id}_row_id");
JAVASCRIPT

            input_txt = text_field_tag("search_quick_search_text_#{input_id}", reference_row_descr, :onkeyup => onkeyup, :autocomplete => :off)
            input_hdn = hidden_field_tag("#{input_name}[row_id]", reference_row.nil? ? '' : reference_row.id)
            result = <<HTML_TAG
#{input_txt} #{input_hdn}
<br>
<div id='_suggest_disp_#{input_id}' class='suggest_disp_hidden'></div>
HTML_TAG
          else
            result = screen_collection_select_tag(
              :assigned_options => reference_row.nil? ? [] : [reference_row],
              :all_options => combo_box_options[:all_options],
              :name => "#{input_name}[row_id]",
              :value_method => :id,
              :text_method => :description,
              :include_blank => true )
          end
        end

      when CustomFields::TextField then
        if options[:read_only] then
          cell = Cell.new(:field_id => custom_field.id, :value => options[:value])
          result = cell.to_html
        else
          result = text_field_tag(input_name, options[:value])
        end
      when CustomFields::LoginField then
        if options[:read_only] then
          cell = Cell.new(:field_id => custom_field.id, :value => options[:value])
          result = cell.to_html
        else
          result = text_field_tag(input_name, options[:value])
        end
      when CustomFields::NumericField then
        options[:value] ||= {}
        options[:value][:from] ||= ''
        options[:value][:to] ||= ''
        if options[:read_only] then
          if options[:value][:from].empty? && options[:value][:to].empty?
            result = ''
          else
            result = [:from, :to].collect do |a| 
              if options[:value][a].empty?
                result = '&hellip;'
              else
                cell = Cell.new(:field_id => custom_field.id, :value => options[:value][a])
                result = cell.to_html
              end
            end.join(' ~ ')
          end
        else
          result = field_numeric_search(input_name, custom_field.id, options[:value])
        end
      when CustomFields::TextArea then
        if options[:read_only] then
          cell = Cell.new(:field_id => custom_field.id, :value => options[:value])
          result = cell.to_html
        else
          result = text_field_tag(input_name, options[:value])
        end
      when CustomFields::UploadImage then
        if options[:read_only] then
          cell = Cell.new(:field_id => custom_field.id, :value => options[:value])
          result = cell.to_html
        else
          result = radio_button_tag(input_name,'uploaded',false) + 'Uploaded '
          result << radio_button_tag(input_name,'notuploaded',false) + 'Not uploaded'
        end
      when CustomFields::UploadFile then
        if options[:read_only] then
          result = options[:value]
        else
          result = radio_button_tag(input_name,'uploaded',false) + 'Uploaded '
          result << radio_button_tag(input_name,'notuploaded',false) + 'Not uploaded'
        end
      when CustomFields::IssueTracking then
        if options[:read_only] then
          cell = Cell.new(:field_id => custom_field.id, :value => options[:value])
          result = cell.to_html
        else
          result = field_for_issue_tracking(input_name,options[:count],options[:fields_per_line])
        end
      when CustomFields::ScreenCombindedReference then
        if options[:read_only] then
          cell = Cell.new(:field_id => custom_field.id, :value => options[:value])
          result = cell.to_html
        else
          result = text_field_tag(input_name, options[:value])
        end
      when CustomFields::OptionCombindedReference then
        cell = Cell.new(:field_id => custom_field.id, :value => options[:value])
        if options[:read_only] then
          result = cell.to_html
        else 
          combo_box_options = cell.select_value_combined_options(field.value[:field_id])
          result = select_tag("#{input_name}[scr_row_id]",
            options_from_collection_for_select_tag(
              combo_box_options[:all_options],
              :id,
              :screen_combined_code,
              combo_box_options[:assigned_options].id, {:include_blank => true,:prompt => ''}))
          result << ' : '
          result << text_field_tag("#{input_name}[text]")
          result << hidden_field_tag("#{input_name}[screen_id]", field.screen_id)
        end
      when CustomFields::CodeCombindedReference then
        cell = Cell.new(:field_id => custom_field.id, :value => options[:value])
        if options[:read_only] then
          result = cell.to_html
        else
          result = text_field_tag(input_name)
        end
      when CustomFields::AutoNumbering then
        if options[:read_only] then
          cell = Cell.new(:field_id => custom_field.id, :value => options[:value])
          result = cell.to_html
        else
          result = field_for_auto_numbering(custom_field, input_name, options)
        end
      when CustomFields::Parameter then
        if options[:read_only] then
          cell = Cell.new(:field_id => custom_field.id, :value => options[:value])
          result = cell.to_html
        else
          result = text_field_tag(input_name, options[:value])
        end
      when CustomFields::Calendar then
        if options[:read_only] then
          cell = Cell.new(:field_id => custom_field.id, :value => options[:value])
          result = cell.to_html
        else
          result = text_field_tag(input_name, options[:value])
          if custom_field.format.to_sym.eql?(:monthly)
            current_year = Time.now.year
            result = select_date(Date.null_date, :prefix => input_name, :discard_month => true, :discard_day => true, :start_year => current_year - 5, :end_year => current_year + 1, :include_blank => true)
          else
            result = '<span class=implementation_missing>Pending</span>'
          end
        end
      else
        result = "<span class=implementation_missing>Please define how to display the search control(s) for the '#{custom_field.class.to_s}' in #{ __FILE__.gsub(RAILS_ROOT, '')}</span>"
        result = '' unless RAILS_ENV =~ /development/
      end

      result << '<span class="required_field">&nbsp;*&nbsp;</span>' if field.required_search?
    end
    
    result
  end

  def field_for_new(name, custom_field, options={})
  end

  def field_for_edit(name, custom_field, options={})
  end

  def field_for_xxx(name, xxx, options={})
  end

  def field_date(id_from)
      text_field_tag(id_from, '', :readonly=>true, :size=>7)  +
        "		<a href='javascript:NewCssCal(\"#{id_from}\",\"yyyymmdd\")' >  " +
        "		<img src='/images/cal.gif' width='16' height='16' alt='Pick a date' border='0'></a>"
  end

  def field_date_search_without_status(name_from, name_to)
      id_from = sanitize_to_id(name_from)
      id_to = sanitize_to_id(name_to)
		  text_field_tag(name_from, '', :readonly=>true, :size=>9)  +
				"		<a href='javascript:NewCssCal(\"#{id_from}\",\"yyyymmdd\")' >  " +
				"		<img src='/images/cal.gif' width='16' height='16' alt='Pick a date' border='0'></a>" +
				' ~ ' +
 			text_field_tag(name_to, '', :readonly=>true, :size=>9) +
				"		<a href='javascript:NewCssCal(\"#{id_to}\",\"yyyymmdd\")' >  " +
				"		<img src='/images/cal.gif' width='16' height='16' alt='Pick a Date' border='0'></a> " +
				"		<img src='/images/cal_close.gif' width='16' height='16' alt='Reset date' border='0' "  +
				"   onClick='javascript:ResetTextBox(\"#{id_to}\");javascript:ResetTextBox(\"#{id_from}\");'> "
   end

  def field_date_search_with_status(field_name, field, screen_id, option_name = '', default_value_from = nil, default_value_to = nil, is_already_set = true, format = nil, is_range = true)
    field_from_name = "#{field_name}[from]"
    field_to_name = "#{field_name}[to]"
    field_from_id = sanitize_to_id(field_from_name)
    field_to_id = sanitize_to_id(field_to_name)
    default_value_from = (default_value_from.nil? || default_value_from == Date.null_date) ? nil : default_value_from.to_date.strftime('%d-%b-%Y')
    default_value_to = (default_value_to.nil? || default_value_to == Date.null_date) ? nil : default_value_to.to_date.strftime('%d-%b-%Y')
    date_format = format.nil? ? CustomField.find(field.custom_field_id).format_date : format
    
    radio_name = "#{field_name}[status][set]"
    radio_id = sanitize_to_id(radio_name)
    onset_radio_already_set = "javascript:fncAlreadySetRadio('#{radio_id}');"

    case date_format
    when :short_date, :long_date then
        onclear = "javascript:ResetTextBox('#{field_from_id}');
                   javascript:ResetTextBox('#{field_to_id}');"
        calendar_name = option_name == :field_filter ? "calendar_#{field.id}_value" : (screen_id.nil?) ? "calendar_#{field.custom_field_id}" : "calendar_#{screen_id}_#{field.custom_field_id}"
        html = text_field_tag(field_from_name, default_value_from, :readonly=>true, :size=>7)
        html << <<IMAGE
<img id="#{calendar_name}_from" src="/images/cal.gif" width="16" height="16" alt="Pick a date" border="0" onClick="javascript:NewCssCal('#{field_from_id}','ddmmmyyyy'); #{onset_radio_already_set}">
IMAGE
         if is_range
          html << '<B> - </B>'
          html << text_field_tag(field_to_name, default_value_to, :readonly=>true, :size=>7)
          html << <<IMAGE
    <img id="#{calendar_name}_to" src="/images/cal.gif" width="16" height="16" alt="Pick a date" border="0" onClick=\"javascript:NewCssCal('#{field_to_id}','ddmmmyyyy'); #{onset_radio_already_set}\">
IMAGE
         end
#
#    html << <<IMAGE
#  <img src='/images/cal_close.gif' width='16' height='16' alt='Reset date' border='0' onClick='#{onclear}'>
#IMAGE
    else
        start_year = (Time.now.year)-10
        end_year = (Time.now.year)+5

        field_from_month = "#{field_from_name}_month"
        field_from_year = "#{field_from_name}_year"
        field_to_month = "#{field_to_name}_month"
        field_to_year = "#{field_to_name}_year"

        onchange_from = "fncSetDate(\"#{date_format}\",\"#{sanitize_to_id("date[#{field_from_month}]")}\",\"#{sanitize_to_id("date[#{field_from_year}]")}\",\"#{field_from_id}\",true, \"#{Date.null_date}\");"
        onchange_from << "fncSetDate(\"#{date_format}\",\"#{sanitize_to_id("date[#{field_from_month}]")}\",\"#{sanitize_to_id("date[#{field_from_year}]")}\",\"#{field_to_id}\",false, \"#{Date.null_date}\");" unless is_range

        onchange_to = "fncSetDate(\"#{date_format}\",\"#{sanitize_to_id("date[#{field_to_month}]")}\",\"#{sanitize_to_id("date[#{field_to_year}]")}\",\"#{field_to_id}\",false, \"#{Date.null_date}\");" if is_range

        onclear = "javascript:fncClearComboBoxDateFormat(\"#{date_format}\",\"#{sanitize_to_id("date[#{field_from_month}]")}\",\"#{sanitize_to_id("date[#{field_from_year}]")}\",\"#{field_from_id}\");
                   javascript:fncClearComboBoxDateFormat(\"#{date_format}\",\"#{sanitize_to_id("date[#{field_to_month}]")}\",\"#{sanitize_to_id("date[#{field_to_year}]")}\",\"#{field_to_id}\");
                   javascript:fncClearInvalidSearch(\"#{field.custom_field_id}\");"
    
        case date_format
        when :year then
            html = select_year(default_value_from,{:field_name => field_from_year, :start_year => start_year, :end_year => end_year, :include_blank => true},{:onchange => onchange_from, :onclick => onset_radio_already_set})
            html << '<B> - </B>' if is_range
            html << select_year(default_value_to,{:field_name => field_to_year, :start_year => start_year,:end_year => end_year,:include_blank => true},{:onchange => onchange_to, :onclick => onset_radio_already_set}) if is_range
        else
            case date_format
            when :short_month, :long_month then
                use_short_month = (date_format == :short_month)
                html = select_month(default_value_from, {:field_name => field_from_month, :use_short_month => use_short_month, :include_blank => true}, {:onchange => onchange_from, :onclick => onset_radio_already_set})
                html << select_year(default_value_from, {:field_name => field_from_year, :start_year => start_year  , :end_year => end_year, :include_blank => true}, {:onchange => onchange_from, :onclick => onset_radio_already_set})
                html << '<B> - </B>' if is_range
                html << select_month(default_value_to, {:field_name => field_to_month, :use_short_month => use_short_month, :include_blank => true}, {:onchange => onchange_to, :onclick => onset_radio_already_set}) if is_range
                html << select_year(default_value_to, {:field_name => field_to_year, :start_year => start_year  , :end_year => end_year, :include_blank => true}, {:onchange => onchange_to, :onclick => onset_radio_already_set}) if is_range
            when :half_year, :quarter_year then
                null_date = Date.null_date
                month_from = default_value_from.nil? ? 0 : null_date == default_value_from ? 0 : default_value_from.month
                month_to =  default_value_to.nil? ? 0 : null_date == default_value_to ? 0 : default_value_to.month
                if date_format == :half_year
                    options = ['','1st Half','2nd Half']
                    period_from = case month_from
                             when 0 then 0
                             when 4..9 then 1
                             else 2
                             end
                    period_to = case month_to
                             when 0 then 0
                             when 4..9 then 1
                             else 2
                             end
                else
                    options = ['','1st Quarter','2nd Quarter','3rd Quarter','4th Quarter']
                    period_from = case month_from
                             when 0 then 0
                             when 4..6 then 1
                             when 7..9 then 2
                             when 10..12 then 3
                             else 4
                             end
                    period_to = case month_to
                             when 0 then 0
                             when 4..6 then 1
                             when 7..9 then 2
                             when 10..12 then 3
                             else 4
                             end
                end
                options_from = options.collect{|o| selected = (options.index(o) == period_from) ? "selected=\"selected\"": "" unless default_value_from.nil?
                           "<option value='#{options.index(o)}' #{selected} >#{o}</option>"}
                options_to = options.collect{|o| selected = (options.index(o) == period_to) ? "selected=\"selected\"": "" unless default_value_to.nil?
                           "<option value='#{options.index(o)}' #{selected} >#{o}</option>"}

                html = select_tag(sanitize_to_id("date[#{field_from_month}]"), options_from, {:onchange => onchange_from, :onclick => onset_radio_already_set, :include_blank => true})
                html << select_year(default_value_from, {:field_name => field_from_year, :start_year => start_year  , :end_year => end_year, :include_blank => true}, {:onchange => onchange_from, :onclick => onset_radio_already_set})
                html << '<B> - </B>' if is_range
                html << select_tag(sanitize_to_id("date[#{field_to_month}]"), options_to, {:onchange => onchange_to, :include_blank => true, :onclick => onset_radio_already_set}) if is_range
                html << select_year(default_value_to, {:field_name => field_to_year, :start_year => start_year  , :end_year => end_year, :include_blank => true}, {:onchange => onchange_to, :onclick => onset_radio_already_set}) if is_range
            end
        end
        html << hidden_field_tag(field_from_name, default_value_from)
        html << hidden_field_tag(field_to_name, default_value_to)
#        html << "<img src='/images/cal_close.gif' width='16' height='16' alt='Reset date' border='0'onClick='#{onclear}'> "
    end
    #----- Adding image for reset date -----#
    html << "<img src=\"/images/cal_close.gif\" width=\"16\" height=\"16\" alt=\"Reset date\" border=\"0\" onClick=\"#{onclear}\">"
  
    #----- Adding radio box-----#
    html << '<br>'
    is_already_set ||= true
    html << radio_button_tag("#{field_name}[status]", 'set',      is_already_set, {:onpropertychange => "fncCheckStatusDateTime(#{field.custom_field_id},'#{screen_id}');"                      }) + 'Already Set'
    html << radio_button_tag("#{field_name}[status]", 'not_set',  !is_already_set,{:onpropertychange => "fncCheckStatusDateTime(#{field.custom_field_id},'#{screen_id}');", :onclick => onclear }) + 'Not Set'
  end

  def field_numeric_search(field_name, cf_id, value = {})
    field_from_name = "#{field_name}[from]"
    field_to_name = "#{field_name}[to]"
    cf_options = CustomField.find(cf_id).option

   options = {:size => 10,
               :onKeyPress => "return checkNumber(event, true, true, '#{cf_options[:separator]}', '#{cf_options[:delimiter]}');",
               :onBlur => "this.value = fncSetNumericFormat(this.value, #{cf_options[:precision].to_i}, '#{cf_options[:separator]}', '#{cf_options[:delimiter]}', true, true);"}
    value ||= {}
    value_from = value[:from]
    value_to = value[:to]

    '<div name="custom_field_numeric">' +
    text_field_tag(field_from_name, value_from, options) + ' ~ ' +
    text_field_tag(field_to_name, value_to, options) +
    hidden_field_tag('precision', cf_options[:precision].nil? ? '' : cf_options[:precision]) +
    hidden_field_tag('separator', cf_options[:separator].nil? ? '' : cf_options[:separator]) +
    hidden_field_tag('delimiter', cf_options[:delimiter].nil? ? '' : cf_options[:delimiter]) +
    '</div>'
  end

  def custom_fields_check_box_path(options)
    custom_field_path(options)
  end

  def custom_fields_combo_box_path(options)
    custom_field_path(options)
  end

  def custom_fields_date_time_field_path(options)
    custom_field_path(options)
  end

  def custom_fields_header_path(options)
    custom_field_path(options)
  end

  def custom_fields_issue_tracking_path(options)
    custom_field_path(options)
  end

  def custom_fields_left_right_path(options)
    custom_field_path(options)
  end

  def custom_fields_list_box_path(options)
    custom_field_path(options)
  end

  def custom_fields_login_field_path(options)
    custom_field_path(options)
  end

  def custom_fields_numeric_field_path(options)
    custom_field_path(options)
  end

  def custom_fields_password_path(options)
    custom_field_path(options)
  end

  def custom_fields_radio_button_path(options)
    custom_field_path(options)
  end

  def custom_fields_reference_path(options)
    custom_field_path(options)
  end

  def custom_fields_text_area_path(options)
    custom_field_path(options)
  end

  def custom_fields_text_field_path(options)
    custom_field_path(options)
  end

  def custom_fields_upload_file_path(options)
    custom_field_path(options)
  end

  def custom_fields_upload_image_path(options)
    custom_field_path(options)
  end

  def custom_fields_screen_combinded_reference_path(options)
    custom_field_path(options)
  end

  def custom_fields_option_combinded_reference_path(options)
    custom_field_path(options)
  end

  def custom_fields_code_combinded_reference_path(options)
    custom_field_path(options)
  end

  def custom_fields_auto_numbering_path(options)
    custom_field_path(options)
  end

  def custom_fields_reference_attribute_path(options)
    custom_field_path(options)
  end

  def custom_fields_code_combinded_reference_attribute_path(options)
    custom_field_path(options)
  end

  def custom_fields_parameter_path(options)
    custom_field_path(options)
  end

  def custom_fields_calendar_path(options)
    custom_field_path(options)
  end

  def custom_fields_stock_quantity_path(options)
    custom_field_path(options)
  end

  def custom_fields_date_time_range_path(options)
    custom_field_path(options)
  end

  def field_for_issue_tracking(custom_field_id,count,fields_per_line)
    result = ''

    date_controls = ['Created_date', 'Dued_date', 'Completed_date']
    check_box_control = {
        :label => 'Status',
        :options => ['Scheduled','Delayed','Dued','Re-Scheduled','Completed','Cancelled']
      }

    #~ ToDo: Get labels and control
    inputs = date_controls.collect do |dc|
      label = dc.titleize
      input = field_date_search_without_status("#{custom_field_id}[#{dc}_from]", "#{custom_field_id}[#{dc}_to]" )

      [label, input]
    end

    input_tags = '<table><tr>'
    check_box_control[:options].each_with_index do |o, i|
      input_tags << '</tr><tr>' if i > 0 && i % 2 == 0
      input_tags << <<HTML_TAG
<td nowrap>
#{check_box_tag("#{custom_field_id}[#{o}]")}
#{label_tag("#{custom_field_id}[#{o}]", o.titleize)}
</td>
HTML_TAG
    end
    input_tags << '</tr></table>'

    inputs << [check_box_control[:label], input_tags]

    #~ ToDo: Gen HTML TAG for each label and control pair
    inputs.each do |label, input|
      new_line = '</tr><tr>' if (count % fields_per_line) == 0

      result << <<HTML_TAG
#{new_line}</tr><tr>
<td class='td_search' nowrap>
  <b>#{label}</b>
</td></tr><tr>
<td class='td_search' nowrap>
  #{input}
</td>
HTML_TAG

      count += 1
    end

    return result, count
  end

  def field_for_auto_numbering(custom_field, input_name, options)
    result = text_field_tag(input_name, options[:value])

    #~ ToDo: Get labels and control
    inputs = custom_field.reference_custom_fields.collect do |cf|
      label = "#{cf.screen.label_descr.titleize} :"
      input = field_for_search(cf, options)

      [label, input]
    end

    #~ ToDo: Gen HTML TAG for each label and control pair
    inputs.each do |label, input|
      new_line = '</tr><tr>' if (options[:count] % options[:fields_per_line]) == 0

      result << <<HTML_TAG
#{new_line}
<td class='td_search' nowrap>
  <b>#{label}</b>
</td>
<td class='td_search' nowrap>
  #{input}
</td>
HTML_TAG

      options[:count] += 1
    end

    options[:count] += 1 unless inputs.empty?

    return result, options[:count]
  end

end