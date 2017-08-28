# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  FLASH_NOTICE_KEYS = [:error, :notice, :warning]

  def flash_messages
    return unless messages = flash.keys.select{|k| FLASH_NOTICE_KEYS.include?(k)}
    formatted_messages = messages.map do |type|
      content_tag :div, :class => type.to_s do
        message_for_item(flash[type], flash["#{type}_item".to_sym])
      end
    end
    flash.clear
    formatted_messages.join
  end

  def message_for_item(message, item = nil)
    if item.is_a?(Array)
      message % link_to(*item)
    else
      message % item
    end
  end
	
	# ============================================
	# create by     : K.Nipat  
	# create when   : 21/01/2009
	# porpose       : create left to right tag list
	# ============================================
  #		defaults = {
  #      :descr => 'unknown',
  #      :name => 'unknown',
  #      :collection => [],
  #      :value_method => 'id',
  #      :text_method => 'descr',
  #      :group_method => nil,
  #      :group_label_method => nil,
  #      :type => :assigned,
  #      :sort => true,
  #      :multiple => true
  #    }
	def left_to_right_tag_list(options={})
		defaults = {
      :descr => 'unknown',
      :name => 'unknown',
      :collection => [],
      :hidden_options => [],
      :value_method => 'id',
      :text_method => 'descr',
      :group_method => nil,
      :group_label_method => nil,
      :type => :assigned,
      :sort => true,
      :multiple => true
    }
    
    options = defaults.merge(options)
    options[:name] = "available_#{options[:name]}" if (options[:type]==:available)

    if options[:sort]
      options[:collection] = sort_list_options(options[:collection], options[:text_method])
    end
    
    if options[:group_method]
      options[:group_label_method] ||= options[:text_method]
      option_tag = option_groups_from_collection_for_select(options[:collection], options[:group_method], options[:group_label_method], options[:value_method], options[:text_method])
    else
      option_tag = options_from_collection_for_select(options[:collection], options[:value_method], options[:text_method] )
    end

    [options[:hidden_options]].flatten.each do |o|
      option_tag.gsub!(/(value="#{o.id}")/, '\1 style="display: none; background-color:gray"')
    end
    
    ondblclick = <<JAVASCRIPT
$("#{sanitize_to_id(options[:name])}single").click();
JAVASCRIPT

		content = select_tag(options[:name], option_tag, 
      :multiple => options[:multiple], 
      :sort => options[:sort], 
      :size=>8, 
      :style=>'width:100%',
      :ondblclick => ondblclick
    )
    content += hidden_field_tag "#{options[:name]}[]", -1
    
    label = (options[:type]==:available) ? 'G_Available' : 'G_Assigned'
    
    descr_prefix = Label.descr_by_name(label).to_s  + ' '

    group_tag(options[:descr].pluralize, content, {:type => 'left2right', :descr_prefix => descr_prefix, :blindable => false})
	end
	
	# ============================================
	# create by     : K.Nipat  
	# create when   : 26/12/2008
	# porpose       : create left to right swap button tag
	# ============================================
  #    defaults = {
  #      :enable_move_all => true,
  #      :sort => true,
  #      :refresh_action => ';',
  #      :multi_selected => false
  #    }
	def left_to_right_swap_button_tag(available_list_id, assigned_list_id, options={})
    defaults = {
      :enable_move_all => true,
      :sort => true,
      :refresh_action => ';',
      :multi_selected => false
    }
    options = defaults.merge(options)

    options[:sort] = false if options[:multi_selected]
    
    sort_flag = (options[:sort]) ? '1' : '0'
    remove_from_flag = (options[:multi_selected]) ? '0' : '1'
    add_to_flag = (options[:multi_selected]) ? '0' : '1'
    
    if options[:multi_selected]
      add_sign = '+'
      rmv_sign = ' -'
    else
      add_sign = '>'
      rmv_sign = '<'
    end
    if options[:enable_move_all]
      btn_left_all = button_to_function(rmv_sign*2, "fncMoveSelectOption(\"#{assigned_list_id}\",\"#{available_list_id}\",1, #{sort_flag}, 1, #{add_to_flag} );#{options[:refresh_action]}", :style=>'width:25px', :id => "#{assigned_list_id}all")
      btn_right_all = button_to_function(add_sign*2, "fncMoveSelectOption(\"#{available_list_id}\",\"#{assigned_list_id}\",1, #{sort_flag}, #{remove_from_flag}, 1);#{options[:refresh_action]}", :style=>'width:25px', :id => "#{available_list_id}all")
    end

    btn_left = button_to_function(" #{rmv_sign} ", "fncMoveSelectOption(\"#{assigned_list_id}\",\"#{available_list_id}\",0, #{sort_flag}, 1, #{add_to_flag} );#{options[:refresh_action]}", :style=>'width:25px', :id => "#{assigned_list_id}single")
    btn_right = button_to_function(" #{add_sign} ", "fncMoveSelectOption(\"#{available_list_id}\",\"#{assigned_list_id}\",0, #{sort_flag}, #{remove_from_flag}, 1);#{options[:refresh_action]}", :style=>'width:25px', :id => "#{available_list_id}single")

		<<HTML_TAG
<td>
  <table>
    <tr><td>#{btn_right_all}</td></tr>
    <tr><td>#{btn_right}</td></tr>
    <tr><td>#{btn_left}</td></tr>
    <tr><td>#{btn_left_all}</td></tr>
  </table>
</td>
HTML_TAG
	end
	
	def reset_tag()
		'<input type="reset">'
	end
	# ============================================
	# create by     : K.Nipat  
	# create when   : 26/12/2008
	# porpose       : create group button
	# ============================================
	
	def group_button(options={})
    defaults = {
      :reused_form => false,
      :save_as => false,
      :area_id => nil,
      :onclick => ''
    }
    options = defaults.merge(options)
    area = options[:area_id].nil? ? '' : "_#{options[:area_id]}"
    cancle_onclick = <<JAVASCRIPT
fncSetElementInnerHtml("operation_area#{area}","");
fncSetElementInnerHtml("relation_area#{area}","");
if ($("field_area#{area}") != null) fncSetElementInnerHtml("field_area#{area}","");
JAVASCRIPT
    
    buttons = reset_tag() +
      submit_tag('Submit', :onclick => options[:onclick]) +
      button_to_function('Cancel', cancle_onclick)

    reuse_input_id = "form_content_reuse#{area}"
    reuse_tag = <<HTML_TAG
  <tr>
    <td align='left'>
      #{check_box_tag('form_content_reuse', true, false, :id => reuse_input_id )}
      #{label_tag(reuse_input_id ,'Keep values for next record (Reuse)')}
    </td>
  </tr>
HTML_TAG

    save_as_input_id = "save_as_new_copy#{area}"
    save_as_tag = <<HTML_TAG
  <tr>
    <td align='left'>
      #{check_box_tag('save_as_new_copy', true, false, :id => save_as_input_id )}
      #{label_tag(save_as_input_id, 'Save as a new record (copy)')}
    </td>
  </tr>
HTML_TAG

    <<HTML_TAG
<table>
  <tr>
    <td align='center'>
      #{buttons}
    </td>
  </tr>
#{reuse_tag if options[:reused_form]}
#{save_as_tag if options[:save_as]}
</table>
HTML_TAG
	end

  # ============================================
	# create by     : P.Surapong
	# create when   : 17/11/2010
	# porpose       : create group button
	# ============================================

	def formula_button()
		reset_tag()+
      submit_tag('Set')
	end
	
	# ============================================
	# create by     : K.Nipat  
	# create when   : 26/12/2008
	# porpose       : create group button
	# ============================================
	def screen_detail_button(options={})
		content_id = options[:content_id]
		area_id = options[:area_id]
		tab_id = options[:tab_id]
		target = options[:target]
		button_to_function('Reset', "fncSetResetOriginalInnerHtml(\"#{area_id}\")") +
      "<input type='button' onClick='fncCopyHTMLToForm(\"#{content_id}\"); fncAjaxUpdater(\"#{tab_id}\",\"#{target}\");' value='Save'>" +
      button_to_function(	'Cancel',"fncSetElementInnerHtml(\"#{area_id}\",\"\");"
		)
	end
	
	# ============================================
	# create by     : Kiattchai  
	# create when   : 19/08/2009
	# porpose       : combo_box
	# ============================================
	
	def screen_combo_box_collection_tag(name,combo_value, options={})
    defaults = {
      :display_method => 'caption.name.to_s'
    }
    options = defaults.merge(options)
    
		html_tag = ''
		html_tag << '<option value=""></option>'
		combo_value[0].each do |o|
      option_text = eval("o.#{options[:display_method]}")
      option_selected = "selected=\"selected\"" if o.id.to_s == combo_value[1]
      
			html_tag << "<option value='#{o.id.to_s}' #{option_selected}>#{option_text}</option>"
		end
    select_tag(name, html_tag)
	end

  def screen_combo_box_collection_tag_visit_purpose(name,combo_value,disabled)
		html_tag = ''
		html_tag << '<option value=""></option>'
		combo_value[0].each do |o|
			if o.id.to_s == combo_value[1]
        selected = 'selected="selected"'
			end
		  html_tag << "<option value='#{o.id.to_s}' #{selected}>#{o.caption.name.to_s}</option>"
		end
    select_tag(name, html_tag,:disabled => disabled)
	end

  def screen_combo_box_collection_tag_visit(name,combo_value)
		html_tag = ''
		html_tag << '<option value=""></option>'
		combo_value[0].each do |o|
			if o.id.to_s == combo_value[1]
			  selected = 'selected="selected"'
			end
		  html_tag << "<option value='#{o.id.to_s}' #{selected}>#{o.caption.name.to_s}</option>"
		end
    select_tag(name, html_tag, :onchange=>"fncChkType('302', '235', this);") # 302 => visit purpose, 235 => Action Type = Visit
	end

  def screen_combo_box_collection_tag_task(name,combo_value)
		html_tag = ''
		html_tag << '<option value=""></option>'
		combo_value[0].each do |o|
			if o.id.to_s == combo_value[1]
			  selected = 'selected="selected"'
			end
		  html_tag << "<option value='#{o.id.to_s}' #{selected}>#{o.caption.name.to_s}</option>"
		end
    #select_tag(name, html_tag)
    select_tag(name, html_tag, :onchange=>"fncChkRadioType('307', '139', this);") # 307 => Task Purpose, 139 => Task Type = task
	end
	
	def get_all_and_selected_value(custom_field, row_id, field_id)
		all_combo = Array.new
		selected_combo = nil
		custom_field.label_ids.each do |c|
			all_combo << Label.find(c)  
		end
		if row_id != nil
			cell = Cell.find(:first, :conditions => ['row_id = ? and field_id = ?', row_id , field_id])
      if cell != nil
        selected_combo = cell.value
      end
		end
		return all_combo,selected_combo
	end

  def field_combo_box_collection_tag(name,custom)
		html_tag = []
		html_tag << "<select name=#{name}>"
		html_tag << '<option value=""></option>'
		custom[0].each do |o|
			if o.id.to_s == custom[1]
			  selected = 'selected="selected"'
			end
		  html_tag << "<option value='#{o.id.to_s}' #{selected}>#{o.name.to_s}</option>"
 		end
		html_tag << '</select>'
	end
	
	# Create left to right tag
	#
  #   defaults = {
  #      :descr => '{Unknown}',
  #      :name => '{Unknown}',
  #      :assigned_options => [],
  #      :all_options => [],
  #      :value_method => 'id',
  #      :text_method => 'descr',
  #      :group_method => nil,
  #      :group_label_method => nil,
  #      :enable_move_all => true,
  #      :multiple => true,
  #      :sort => true,
  #      :refresh_action => ';',
  #      :multi_selected => false
  #    }
	def left_to_right_tag(options={})
    defaults = {
      :descr => '{Unknown}',
      :name => '{Unknown}',
      :assigned_options => [],
      :all_options => [],
      :value_method => 'id',
      :text_method => 'descr',
      :group_method => nil,
      :group_label_method => nil,
      :enable_move_all => true,
      :multiple => true,
      :sort => true,
      :refresh_action => ';',
      :multi_selected => false
    }
    options = defaults.merge(options)
    options = options.merge( options[:left_to_right_options] ) unless options[:left_to_right_options].nil?
    options.delete(:left_to_right_options)

    options[:sort] = false if options[:multi_selected]

		options = options.merge(
      :collection => options[:all_options],
      :hidden_options => options[:assigned_options],
      :type => :available
    )

    available_select_list_tag = left_to_right_tag_list(options)

    options.delete(:hidden_options)
    
    options = options.merge(
      :collection => options[:assigned_options],
      :type => :assigned
    )

    options.delete(:group_method)
    options.delete(:group_label_method)

    assigned_select_list_tag = left_to_right_tag_list(options)
		
    assigned_list_id = sanitize_to_id( options[:name] )
    available_list_id = sanitize_to_id("available_#{options[:name]}")
    
		swap_button_tag = left_to_right_swap_button_tag(available_list_id, assigned_list_id, options)

		<<HTML_TAG
<table border='0' cellspacing='0' cellpadding='0'>
  <tr>
    <td align='center' width='0%'>#{available_select_list_tag}</td>
    <td align='center' width='0%'>#{swap_button_tag}          </td>
    <td align='center' width='0%'>#{assigned_select_list_tag} </td>
  </tr>
</table>
HTML_TAG
	end
  
  def screen_creation_tag(screen,content, id = '')
    operation = " #{Label.descr_by_name('G_Creation').to_s}"

    group_tag(screen, content, {:descr_postfix => operation, :type => 'form', :blindable => false, :id => id} )
	end
  
  def screen_show_tag(screen,content, id = '')
    operation = " #{Label.descr_by_name('G_Display').to_s}"

    group_tag(screen, content, {:descr_postfix => operation, :type => 'form', :blindable => false, :id => id} )
	end

  def screen_modification_tag(screen, content, id = '')
    operation = " #{Label.descr_by_name('G_Modification').to_s}"
    
    group_tag(screen, content, {:descr_postfix => operation, :type => 'form', :blindable => false, :id => id} )
	end

	# ============================================
	# create by     : K.Nipat  
	# create when   : 05/01/2009
	# porpose       : create Group Tag
	# ============================================
  #    defaults = {
  #      :type => 'group',
  #      :blindable => true,
  #      :descr_prefix => '',
  #      :descr_postfix => '',
  #      :id => ''
  #    }
	def group_tag(descr, content, options={})
    defaults = {
      :type => 'group',
      :blindable => true,
      :descr_prefix => '',
      :descr_postfix => '',
      :id => ''
    }
    options = defaults.merge(options)

    descr ||= '{unknown}'

    id ||= (descr.kind_of?(Screen) ? descr.id.to_s : sanitize_to_id(descr.to_s) )

    descr = (descr.kind_of?(Screen) ? descr.label_descr.to_s : descr.to_s)
    descr = "#{options[:descr_prefix]}#{descr}#{options[:descr_postfix]}"
    
    content_class ="#{options[:type]}_content"
    content_id = options[:id].empty? ? "grp_content_#{id}" : options[:id]

    grp_tag = group_header_tag(descr, content_id, options)

		<<HTML_TAG
<table class='group' cellSpacing='0' cellPadding='0' border='0' width='auto'>
  <tr>
    <td>#{grp_tag}</td>
  </tr>
  <tr>
    <td>
      <div class='#{content_class}' id='#{content_id}'>#{content}</div>
    </td>
  </tr>
</table>
HTML_TAG
	end

  #	defaults = {
  #      :blindable => false,
  #      :descr_prefix => '',
  #      :descr_post => ''
  #    }
	def group_header_tag(group_descr, content_id, options={})
    defaults = {
      :blindable => false,
      :descr_prefix => '',
      :descr_post => ''
    }
    options = defaults.merge(options)

    blinding_image = (options[:blindable]) ? blinding_image_tag( content_id ) : '&nbsp;'

    <<HTML_TAG
      <table class='group_caption' cellSpacing='0' cellPadding='0' width='100%' border='0'>
        <tr>
          <TH class='group_caption_left'>&nbsp;</TH>
          <TH class='group_caption_center' NOWRAP>#{group_descr}</TH>
          <TH class='group_caption_blind'>#{blinding_image}</TH>
          <TH class='group_caption_right'>&nbsp;</TH>
        </tr>
      </table>
HTML_TAG
  end

  def blinding_image_tag(content_id)
    blinding_image_id = "bld_img_#{content_id}"

    <<HTML_TAG
<a href='' blinding_state='1' onClick='fncBlindGroup( this, "#{blinding_image_id}", "#{content_id}" ); return false;'>
  <img id='#{blinding_image_id}' width='14' height='14' border='0' src='/images/blind_up.gif' >
</a>
HTML_TAG
  end

	# ============================================
	# create by     : K.Nipat  
	# create when   : 14/01/2009
	# porpose       : create radio button collection tag
	# ============================================

  def radio_button_collection_tag(options)
    cf_id = options[:customs_fields_id]
    radio_options = options[:radio_options]
    assigned_option = options[:assigned_label_id]
    token = options[:token]
    name = options[:name] || "cells[#{cf_id}]"
    events = options[:events] || ''
    html_tag = []

    if assigned_option != '' # edit(new data it can't be blank)
      assigned_option['label'] = assigned_option[:label] if assigned_option.has_key?(:label)
      if assigned_option['label'].nil?
        assigned_id = assigned_option.to_i
      else
        assigned_id = assigned_option['label'].to_i
      end
      radio_options.each do |option|
        checked = !option.nil? && (assigned_id == option.id)
        if option.nil?
          html_tag << '<span class="missing_implementation">The Label for this option is missing</span>'
        elsif option.name == 'G_Other'
          html_tag << radio_button_tag("#{name}[label]", option.id, checked, :onClick => "fncOnOffTextfieldinRadioBox(#{cf_id},\"#{option.id}\");") + option.descr + '&nbsp;&nbsp;' + text_field_tag("#{name}[text]", assigned_option['text'], :disabled => !checked)
        else
          html_tag << radio_button_tag("#{name}[label]", option.id, checked, :onclick => events) + label_tag("#{name}[label]_#{option.id}", option.descr)
        end
      end
    else # new and edit(old data it can be blank)
      radio_options.each_with_index do |option,index|
        checked = !option.nil? && (index == 0)
        if option.nil?
          html_tag << '<span class="missing_implementation">The Label for this option is missing</span>'
        elsif option.name == 'G_Other'
          assigned_text = ''
          html_tag << radio_button_tag("#{name}[label]", option.id, checked, :onClick => "fncOnOffTextfieldinRadioBox(#{cf_id},\"#{option.id}\");") + option.descr + '&nbsp;&nbsp;' + text_field_tag("#{name}[text]", assigned_option['text'], :disabled => !checked)
        else
          html_tag << radio_button_tag("#{name}[label]", option.id, checked) + label_tag("#{name}[label]_#{option.id}", option.descr)
        end
      end
    end
    html_tag.join(token)
  end
	
	# ============================================
	# create by     : K.Nipat  
	# create when   : 15/01/2009
	# porpose       : create check_box_collection_tag
	# ============================================
	
	def check_box_collection_tag(options)
		# defaults = {:token=>''}
    # options.merge(defaults)
		name = options[:name]
		check_box_label_descr = options[:check_box_label_descr]
		check_box_options = options[:check_box_options]
		assigned_option_id = options[:assigned_label_id] || {}
		token = options[:token]
    custom_field_id = (options[:customs_fields_id]).to_s
    chk_box_type = options[:chk_box_type] || ''
    html_tag = [label_tag(check_box_label_descr)]
    
    check_box_options.each do |o|
      if !chk_box_type.empty? && chk_box_type.to_sym == :single
        checked = assigned_option_id.include?('checked') || CustomFields::CheckBox.true_or_false?(assigned_option_id['0'])
        input_name = "#{name}[0]"
        html_tag << check_box_tag(input_name, true, checked )
        html_tag << label_tag(input_name, o.descr)
        html_tag << '<br />'
      else
        chk = !o.nil? && !assigned_option_id.empty? && CustomFields::CheckBox.true_or_false?(assigned_option_id[o.id.to_s])
        if o.nil?
          html_tag << '<span class="missing_implementation">The Label for this option is missing</span><br />'
        elsif o.name != 'G_Other' && chk_box_type != 'single'
          input_name = "#{name}[#{o.id}]"
          html_tag << check_box_tag(input_name, true, chk )
          html_tag << label_tag(input_name, o.descr)
          html_tag << '<br />'
        else
          input_name = "other_checkbox[#{custom_field_id}]"
          html_tag << check_box_tag(input_name, chk, chk, :onclick => "fncOnOffTextfieldinCheckBox(#{custom_field_id},\"#{o.id}\");" )
          html_tag << label_tag(input_name, o.descr)
          html_tag << '&nbsp;&nbsp;'
          
          input_name = "#{name}[#{o.id}]"
          html_tag << text_field_tag(input_name, chk ? assigned_option_id["#{o.id}"] : '', :disabled => !chk)
        end
      end
    end
    
    # Add an empty hidden field to force passing the check_box
    # param even though nothing was check
    html_tag << hidden_field_tag("#{name}[-1]", value = false)
    html_tag.join(token)

	end
	
	# ============================================
	# create by     : K.Nipat  
	# create when   : 15/01/2009
	# porpose       : create radio_button
	# ============================================
	
	def radio_button(collection,token,option)
		collection.collect do |e|		 
			@add_radio = radio_button_tag('custom_field[field_type_id]', e.id, false, option) + e.name + '<br />' + e.descr
		end.join(token)
	end
	
	# ============================================
	# create by     : K.Nipat  
	# create when   : 05/01/2009
	# porpose       : create Operation Tag
	# ============================================
	
	def operation_tag(operation=[], options={}, html_options={})
		# Specify the displaying order, and the valid operations
		order = [:back, :home, :new, :delete, :export, :import, :print, :print2, :next, :edit, :display_seq]
		
		id = options[:id].to_i
		actions = options[:actions] || {}
		ajax_params = options[:ajax_params] || {}
    
		# Filter out the unsupported operations, and sort them
		operation = (order & operation.collect).sort{|a,b| order.index(a) <=> order.index(b)}
		
		# Build the <A  HREF> tag for each operation, and join with '|'
		html_tags = operation.collect  do |o|
      html_options[o] ||= {}
      html_options[o][:onClick] ||= ''
      html_options[o][:onClick] << operation_ajax_onclick_options(o, id, ajax_params)
      html_options[o][:name] ||= "operation[#{id}][#{o}]"
      html_options[o][:style] ||= 'color: #BBF;' if o == :delete
      html_options[o][:target] ||= '_blank' if o == :print

			link_to o.to_s.titleize, operation_path(o, id, actions), o == :print ? html_options[o].merge({:popup => 'new_window'}) : html_options[o]
		end.join(' | ')

    <<HTML_TAG
<table class='operation_container' name='operation_links_#{id}'>
    <tr>
        <td>#{html_tags}</td>
        <td style='text-align:right'>#{options[:pagination]}</td>
    </td>
</table>
HTML_TAG
	end
	
	def operation_path(option, id, actions)
		case option
    when :back
      :back
    when :home, :new, :delete, :export, :import
      '#'
    when :print
      url_for(:controller => 'report_templates', :action=>:show, :id => 0, :screen_id => id)
		end
	end

  def operation_ajax_onclick_options(operation, id, params)
    controller = params[:controller]
    case operation
    when :new, :export, :import
      params[:screen_id] ||= ''
      suffix = params[:screen_id].to_s == '' ? '' : "_#{params[:screen_id].to_s}"
      url_param = {:action=>operation, :id => id, :params => params}
      url_param[:controller] = controller if controller
      operation_url_option = url_for(url_param)
      <<JAVASCRIPT
fncClearErr();
fncLoadTempFrame();
fncAjaxUpdater('operation_area#{suffix}', '#{operation_url_option}');
return false;
JAVASCRIPT
    when :delete
       <<JAVASCRIPT 
fncDeleteSelected("#{params[:screen_id]}");
return false;
JAVASCRIPT
    else
      ''
    end
  end
        
	# ============================================
	# create by     : K.Nipat  
	# create when   : 05/01/2009
	# porpose       : create Screen Name List Tag
	# ============================================

	def screen_name_list_tag(screen)
    list_label_descr = Label.descr_by_name('G_List') if screen

    case screen
    when NilClass then
			screen_name = 'n/a'
    when String then
      screen_name = screen
    when Screen then
      screen_name = screen.label_descr
    end

    if Language.active.name == 'TH'
      screen_name = "#{list_label_descr}#{screen_name}"
    else
      screen_name = "#{screen_name} #{list_label_descr}"
    end

		return anchor('page_top') + "<h1>" + screen_name + "</h1>"
	end

	# ============================================
	# create by     : K.Nipat  
	# create when   : 19/01/2009
	# porpose       : create screen collection select tag
	# ============================================
	
	def screen_collection_select_tag(options)
		name = options[:name]
		value_method = options[:value_method]
		text_method = options[:text_method]
		assinged_option = ''
    assinged_option = options[:assigned_options][0][value_method] || '' unless options[:assigned_options].empty?
		available_collection = options[:all_options]
    available_collection = available_collection.select{|o| 
      txt = o.send(text_method).to_s

      !txt.empty? && txt !~ /missing_implementation/
    } unless Rails.env =~ /development/
		include_blank = options[:include_blank]
    #   related_from = options[:related_from] || ''
    relate_to = options[:relate_to] || ''
    from_cf_id = options[:from_cf_id] || ''
    on_change = options[:on_change] || ''
		
		option_tag = ''
    option_tag << '<option value=""></option>' if include_blank
    
    if options[:group_method]
      options[:group_label_method] ||= options[:text_method]
      option_tag << option_groups_from_collection_for_select( available_collection, options[:group_method], options[:group_label_method], value_method, text_method, assinged_option )
    else
      option_tag << options_from_collection_for_select( available_collection, value_method, text_method, assinged_option )
    end
    
		if relate_to == '' || relate_to == 0
      select_tag(name, option_tag,:onchange=>on_change, :class => 'seach_input_full')
    else
      select_tag(name, option_tag, :onchange=>"fncReloadComboRef('#{relate_to}', this, '#{from_cf_id}');" + on_change, :class => 'seach_input_full')
    end
		
	end
	
	# ============================================
	# create by     : K.Nipat  
	# create when   : 19/01/2009
	# porpose       : create screen select tag
	# ============================================
	
	def screen_select_tag(options)
		select_tag( 
			options[:name],
			options[:all_options],
			options[:assigned_options]
		)
	end
	
  # Field for set options a +text+. You can customize the option in the +options+ hash.
  # ==== Options
  # * <tt>:name</tt>          - Sets field's name.
  # * <tt>:cell_value</tt>    - Sets field's value.
  # * <tt>:size</tt>          - Sets size of field (defaults to '40x50').
  # * <tt>:maxlength</tt>     - Sets length of characters that user can input.
  # * Any other key creates standard HTML attributes for the tag.
  #
  # ==============================================
	#  create by      : K.Nipat  
	#  create when    : 19/01/2009
	#  porpose        : create screen_text_area_tag
  #  modified       : for support text field option. => [B.Wareerat 01/02/2011]
	# ==============================================
	def screen_text_area_tag(options)
		name = options.delete(:name)
    cell_value = options.delete(:cell_value)
    options[:size] ||= '40x5'
		text_area_tag(name, cell_value, options)
	end
  
  # =====================================================
  # create by     : S.Paitoon
  # create when   : 25/08/2009
  # porpose       : create screen_upload_file_field_tag
  # =====================================================
	
  #	def screen_upload_file_field_tag(options)
  #		name = options[:name]
  #		cell_value = options[:cell_value]
  #		file_field(name, 'file', :id => 'upload_file')
  #	end
  #

	# Field for set options a +text+. You can customize the option in the +options+ hash.
  # 
  # ==== Options
  # * <tt>:name</tt>              - Sets field's name.
  # * <tt>:cell_value</tt>        - Sets field's value.
  # * <tt>:size</tt>              - Sets size of field (defaults to 50).
  # * <tt>:maxlength</tt>         - Sets length of characters that user can input.
  # * Any other key creates standard HTML attributes for the tag.
  #
  # ==================================================================================
	#  created by     : K.Nipat
	#  created when   : 19/01/2009
	#  porpose        : create screen_text_field_tag
  #  modified       : for support text field option. => [B.Wareerat 01/02/2011]
	# ==================================================================================
	def screen_text_field_tag(options)
		name = options.delete(:name)
    cell_value = options.delete(:cell_value)
    options[:size] ||= 50
		text_field_tag(name, cell_value, options)
	end
    
  # Field for set formats a +numeric+. You can customize the format in the +options+ hash.
  # 
  # ==== Options
  # * <tt>:name</tt>       - Sets field's name.
  # * <tt>:cell_value</tt> - Sets field's value.
  # * <tt>:precision</tt>  - Sets the level of precision (defaults to 2).
  # * <tt>:separator</tt>  - Sets the separator between the units (defaults to '.').
  # * <tt>:delimiter</tt>  - Sets the thousands delimiter (defaults to ',').
  # * <tt>:isFloat</tt>    - To specify field's type that include float or not (defaults to true).
  # * <tt>:isMinus</tt>    - To specify field's type that include negative numbers or not (defaults to true).
  #
  # ==== Examples
  #   if :cell_value => 12345678.901                                                           #=> 12,345,678.90
  #   if :cell_value => 12345678.901, :precision =>5, :separator =>'_', :delemiter =>'*'       #=> 12*345*678_99900
  #   if :cell_value => -12345678.901, :isFloat => false                                       #=> -12,345,679
  #   if :cell_value => -12345678.901, :isFloat => false, :isMinus => false                    #=> 12,345,679
  # 
  # ==========================================================================================
	#  created by     : S.Paitoon .
	#  created when   : 06/09/2009.
	#  porpose        : create screen_numeric_field_tag.
  #  modified       : for support firefox event and numeric field options. => [B.Wareerat 11/01/2011]
	# ==========================================================================================
  def screen_numeric_field_tag(options)
    defaults = {:precision => 2,
      :separator => '.',
      :delimiter => ',',
      :isFloat => true,
      :isMinus => true,
      :type => 'text',
      :style => 'text-align:right'}
    options = defaults.merge(options)
    if options[:isFloat] == false || options[:precision] == 0
      options[:precision] = 0 unless options[:precision] == 0
      options[:isFloat] = false unless options[:isFloat] == false
    else
      options[:step] = 1.to_f/(10**options[:precision].to_i)
    end  
    options[:onKeyPress] = "return checkNumber(event,#{options[:isFloat]},#{options[:isMinus]},'#{options[:separator]}','#{options[:delimiter]}');"
    options[:onBlur] = "this.value = fncSetNumericFormat(this.value, #{options[:precision].to_i}, '#{options[:separator]}', '#{options[:delimiter]}', true, false);"

    name = options.delete(:name)
    cell_value = options.delete(:cell_value)
    
    text_field_tag(name, cell_value, options)
  end

  # Field for +number+ only.
  #
  # ==== Options
  # * <tt>:name</tt>              - Sets field's name.
  # * <tt>:cell_value</tt>        - Sets field's value.
  # * <tt>:size</tt>              - Sets size of field (defaults to 50).
  # * <tt>:maxlength</tt>         - Sets length of numeric that user can input.
  # * Any other key creates standard HTML attributes for the tag.
  # 
  # ==========================================================================================
	#  created by     : B.Wareerat
	#  created when   : 14/02/2011
	#  porpose        : create screen_number_field_tag.
	# ==========================================================================================
  def screen_number_field_tag(options)
    defaults = {:type => 'number',
      :style => 'text-align:right',
      :onKeyPress => 'return checkNumber(event,false,false);'}
    options = defaults.merge(options)
    options[:size] = 50 if options[:size].to_s.empty?

		name = options.delete(:name)
    cell_value = options.delete(:cell_value)

    text_field_tag(name, cell_value, options)
  end

	# ============================================
	# create by     : S.Paitoon  
	# create when   : 27/08/2009
	# porpose       : create screen_login_field_tag
	# ============================================
  def screen_login_field_tag(option)
    name = option[:name]
    users = option[:custom]
    cell_value = option[:cell_value]
    
    select_tag name, options_from_collection_for_select_tag(users, :login, :login, cell_value.to_s)
  end
	
	# ============================================
	# create by     : S.Paitoon  
	# create when   : 26/08/2009
	# porpose       : create screen_password_field_tag
	# ============================================
	
	def screen_password_field_tag(options)
		name = options[:name]
		cell_value = options[:cell_value]
		password_field_tag(name, cell_value, :id => 'password', :maxlength => '12') # + hidden_field_tag(name, nil, :id=>'pass_hidden')
	end	
	
  # defaults = {
  #    :screen => nil,
  #    :object => nil,
  #    :action => 'create'
  #  }
	def tab_tag(options={})
    defaults = {
      :screens => [], 
      :active_row => nil,
      :action => 'create'
    }
    options = defaults.merge(options)

    if options[:screens] && options[:active_row]
      name = sanitize_to_id("tab_#{options[:active_row].id}_#{options[:action]}")
      selected_tab_id = sanitize_to_id("#{name}_#{options[:screens][0].id}")
      options[:name] = name
      <<HTML_TAG
<table class="tab_table" id="#{name}"  selected_tab="#{selected_tab_id}" style="padding:0px;border-spacing:0px;">
  #{tab_button(options)}
  #{tab_button_text(options)}
  #{tab_page(options)}
</table><br />
HTML_TAG
    else
      "Unable to render tab control for <pre>#{options.to_yaml}</pre>"
    end

	end

  #	defaults = {
  #      :name => '',
  #      :screen => nil
  #    }
	def tab_button(options={})
    defaults = {
      :name => '',
      :screens => nil
    }
    options = defaults.merge(options)

		tab_top = ''
    screens = options[:screens]

		screens.each_with_index do |s, i|
			tab_id = sanitize_to_id("#{options[:name]}_#{s.id}")
      selected = (i==0) ? '_selected' : ''

			tab_top << <<HTML_TAG
<td class='tab_button_header'>
  <table class='tab_table' style='width:100%;padding:0px;border-spacing:0px;'>
    <tr>
      <td class='tab_button_top_left#{selected}' id='#{tab_id}_top_left'></td>
      <td class='tab_button_top#{selected}' id='#{tab_id}_top'></td>
      <td class='tab_button_top_right#{selected}' id='#{tab_id}_top_right'></td>
    </tr>
  </table>
</td>
HTML_TAG
		end
    
		<<HTML_TAG
<tr valign='bottom'>
  #{tab_top} 
</tr>
HTML_TAG
	end

  #    defaults = {
  #      :name => '',
  #      :screen => nil
  #    }
	def tab_button_text(options={})
    defaults = {
      :name => '',
      :screens => nil
    }
    options = defaults.merge(options)

		tab_text = ''
    screens = options[:screens]

		screens.each_with_index do |s, i|
			tab_id = sanitize_to_id("#{options[:name]}_#{s.id}")
      selected = '_selected' if (i==0)
      border_left = 'style=""' if (i==0)

			tab_text << <<HTML_TAG
<td class = 'tab_button#{selected}' id = '#{tab_id}' onClick='fncOnCilckTab(this.id);'>
  #{s.label_descr}
</td>
HTML_TAG
		end

		<<HTML_TAG
<tr>
    #{tab_text}
</tr>
HTML_TAG
	end

  #  defaults = {
  #    :name => '',
  #    :screens => [],
  #    :active_row => nil
  #  }
	def tab_page(options={})
		defaults = {
      :name => '',
      :screens => [],
      :active_row => nil
    }
    options = defaults.merge(options)

    html_tags = ''
    tab_name = options[:name]
		row = options[:active_row]
    screens = options[:screens]
    
		screens.each_with_index do |s, i|
			tab_id = sanitize_to_id("#{tab_name}_#{s.id}_content")
      div_name = 'on_load_default_tab_content'

      controller = s.class.name.gsub(/Screen/, 'Row').underscore.pluralize

			html_tags << <<HTML_TAG
<div class='tab_content#{(i==0) ? '_selected' : ''}' id='#{tab_id}' name='#{div_name}'
    status='unloaded'
    ajax_result_id='#{tab_id}'
    ajax_url='/#{controller}/index/#{s.id}?row_id=#{row.id}&tab_id=#{tab_id}'
>
</div>
HTML_TAG
		end

    <<HTML_TAG
<tr class ='tab_page_background'>
  <td class = 'tab_page_body' colspan = '#{(screens.length*3) + 1}'>
    #{html_tags}
  </td>
</tr>
HTML_TAG
	end
	
	def relation_div(screen, custom_fields={})
		html_tags = ''
		relation_id = sanitize_to_id("relation_area_#{screen.id}_content")
		
    ajax_url_option = url_for(:controller=>'rows', :action=>'search', :id => screen.id,
      :action_source => 'relations', :custom_fields=>custom_fields)
      
		div_id = "relation_area_#{relation_id}"
    opt_div_id = "operation_area_#{screen.id}"
		html_tags << "<div id = '#{div_id}' name='on_load_relation_content' status='unloaded' ajax_result_id='#{div_id}' ajax_url='#{ajax_url_option}'></div>"
    html_tags << "<div id = '#{opt_div_id}' > </div>"
	end
	
	def form_options(form_id, method)
		{
      :id => form_id,
			:method => method,
      :onSubmit => 'fncPrepareFormForSubmit(this);',
			:onActivate => 'fncActivate(this); return true;',
			:onReset => 'fncReset(this); return false;',
			:original_inner_html => '',
      :target => 'tmp_frame'
		}
	end	
	
	def link_to_destroy(options={})
    defaults = {
      :controller => nil,
      :confirm => true, 
      :onclick => '',
      :object => nil
    }
    
    options = defaults.merge(options) 
		# Can't use 'method' and 'onclick' at the same time
		# No pop-up
		# No method
		
		# Confirm T/F, use multi-lang for text (F:Nil)'Are you sure?'
		confirm_msg = options[:confirm] ? Label.descr_by_name('G_CONFIRM') : nil
    onclick_script = options[:onclick]

    img_alt = "Delete #{options[:object].description}" unless options[:object].nil?
		delete_button = image_tag('delete.png', :alt => img_alt, :title => img_alt, :border => 0)

    link_id = "delete_#{options[:object].id}"
		if not onclick_script.empty?
			if options[:confirm] 
				onclick_script = "if (#{confirm_javascript_function(confirm_msg)}) { #{onclick_script} };return false;"
			end
      link_to_options = { :action => :destroy, :id => options[:object].id }
      link_to_options[:controller] = options[:controller] if options[:controller]
      link_to_options[:screen_id] = options[:object].screen_id if link_to_options[:screen_id].nil? && options[:object].respond_to?(:screen_id)
			link_to delete_button, link_to_options, {:onclick => onclick_script, :id => link_id}
		else
			link_to delete_button, options[:object], :confirm => confirm_msg, :method => :delete, :id => link_id
		end
	end
    
	# ============================================
	# create by     : Paitoon 
	# create when   : 19/08/2009
	# porpose       : search_button
	# ============================================
	
	def search_button(options={})
    defaults = {
    }

    options = defaults.merge(options)

    <<HTML_TAGS
<input id='reset_search' type='reset' onClick='javascript:fncResetInvalidSearch(); javascript:fncResetSelectSearch();'/>
<input type='submit' onClick='javascript:fncSubmitSearch();' value='Search'/>
HTML_TAGS
	end	
    
  # ============================================
	# create by     : Kiattchai 
	# create when   : 9/09/2009
	# porpose       : issue_tracking_tag
	# ============================================

  def issue_tracking_tag(name,value,customs_fields_id)

    html_tags = ''

    # Adding Created Tag
    created_date = (value['Created_date'].nil?) ? Time.now.strftime('%Y-%m-%d') : value['Created_date']
    html_tags << hidden_field_tag("#{name}[Created_date]", created_date)

    # Adding Completed Tag
    disable_completed_check_box = (value == '' || value['Due_date'] == '')
    tracking_completed = false
    completed_date = ''
    if value['Completed_date'] != nil
      tracking_completed = true
      completed_date = value['Completed_date']
    end
    html_tags << check_box_tag("completed_checkbox_#{customs_fields_id}", true, tracking_completed,:disabled => disable_completed_check_box,
      :onclick => "fncCheckBoxIssueTracking(#{customs_fields_id});") + ' Completed '
    html_tags << 'On : ' + text_field_tag("#{name}[Completed_date]", completed_date, :size => 10, :readonly => true, :disabled => !tracking_completed) + '<br />'

    due_date = (value == '') ? '' : value['Due_date']
    original_date = (value == '') ? '' : value['Original_date']
    # Adding Due date 
    duedate_js = "fncCheckDueDateTracking(#{customs_fields_id},\"#{original_date}\");"

    cell_input_name = "#{name}[Due_date]"
    cell_input_id = sanitize_to_id(cell_input_name)

    html_tags << 'Due Date : ' + text_field_tag(cell_input_name, due_date, :size => 10, :readonly=>true, :onfocus => duedate_js, :onblur => duedate_js) + '&nbsp;'
    html_tags << calendar_tag(cell_input_id)

    # Adding Original date  
    html_tags << hidden_field_tag("#{name}[Original_date]",original_date)
    html_tags << 'Original Date : ' + label_tag("original_label_#{customs_fields_id}",original_date) if (original_date != due_date)
   
    return html_tags
  end

  def calendar_tag(text_field_REF, name_postfix=nil)
    html_tags = "&nbsp;<img id='#{text_field_REF}_calendar' src=\"/images/cal.gif\" width=\"16\" height=\"16\" alt=\"Pick a date\" border=\"0\" onClick=\"javascript:NewCssCal('#{text_field_REF}','yyyymmdd');\">&nbsp;" 
    unless name_postfix == 'from'
      reset_all = name_postfix == 'to' ? "javascript:ResetTextBox('#{text_field_REF.sub('to', 'from')}');javascript:ResetTextBox('#{text_field_REF.sub('to', 'from')}_text');" : ''
      html_tags << "<img id='#{text_field_REF}_clear' src=\"/images/cal_close.gif\" width=\"16\" height=\"16\" alt=\"Reset date\" border=\"0\" onClick=\"javascript:ResetTextBox('#{text_field_REF}');javascript:ResetTextBox('#{text_field_REF}_text');#{reset_all}\">&nbsp;"
    end
    html_tags
  end

  def page_tag(screen_id, pageno, maxpage, action_source, row_pattern_id = nil, row_count = nil, number_of_page_links = 7)
    html_tags = []
    html_tags << "#{number_with_precision(row_count, :precision => 0, :delimiter => ',')} records" if row_count
    if maxpage > 1
      first_page = pageno - (number_of_page_links.to_f / 2).floor
      last_page = pageno + (number_of_page_links.to_f / 2).floor

      shift_up = [first_page, 1].max - first_page
      shift_dw = [last_page, maxpage].min - last_page
      first_page += shift_up + shift_dw
      last_page += shift_up + shift_dw

      page_tags = []

      if first_page > 1
        page_tags << { :title => 'First page', :page => 1, :descr => '|<' }
        page_tags << { :title => 'Previous #{number_of_page_links} pages', :page => [pageno-number_of_page_links, 1].max, :descr => '<<' }
      end
      if pageno > 1
        page_tags << { :title => 'Previous page', :page => pageno-1, :descr => '<' }
      end
      for i in (first_page..last_page)
        url_i = { :title => "Page #{i}", :page => (i == pageno) ? nil : i, :descr => i.to_s }

        page_tags << url_i if (i>0) and (i<=maxpage)
      end
      if pageno < maxpage
        page_tags << { :title => 'Next page', :page => pageno+1, :descr => '>' }
      end
      if last_page < maxpage
        page_tags << { :title => 'Next #{number_of_page_links} pages', :page => [pageno+number_of_page_links, maxpage].min, :descr => '>>' }
        page_tags << { :title => 'Last page', :page => maxpage, :descr => '>|' }
      end
      html_tags += page_tags.collect{|p|
        if p[:page]
          <<HTML_TAG
<a class='page_link' href='#' title='#{p[:title]}' onclick='fncAjaxAbort(); fncAjaxUpdater("main", "#{gen_url_for_pagination(p[:page], screen_id, action_source, row_pattern_id)}/"); return false;'>#{p[:descr]}</a>
HTML_TAG
        else
          <<HTML_TAG
<span class='selected_page'>#{p[:descr]}</span>
HTML_TAG
        end
      }
      html_tags << "(#{maxpage} pages)"
    end
    html_tags.join(' ')
  end

  def gen_url_for_pagination(page_number,screen_id,action_source, row_pattern_id, sort_field_id = nil)
    url_for(:action=>'index', :id=>screen_id, :pageno=>page_number, :action_source=>action_source, :row_pattern_id => row_pattern_id, :sort_field_id => sort_field_id)
  end

  def table_hr_tag(style_class = '')
    "<tr><td class='table_hr #{style_class}' colspan='99'><hr /></td></tr>"
  end

  #  defaults = {
  #    :descr => '',
  #    :break => true
  #  }
  def field_descr_tag(options={})
    defaults = {
      :descr => RAILS_ENV =~ /development/ ? 'Please add description on how to use this field, or what is it used for.' : '',
      :break => true
    }

    options = defaults.merge(options)
    
    "#{'<br />' if options[:break]}<span class='field_descr'>#{options[:descr]}</span>" unless options[:descr]==defaults[:descr] and !(RAILS_ENV =~ /development/)
  end

  def options_from_collection_for_select_tag(collection, value_method, text_method, selected = nil, options={})
    defaults = {
      :include_blank => false,
      :prompt => 'Please select',
      :prompt_value => nil,
      :include_all => false
    }

    options = defaults.merge(options)
    # NO BLANK
    #<option value=''></option>
    #<option value=''>Please select</option>
    #<option value=''>My Text</option>

    tags = []
    tags << "<option value='#{options[:prompt_value]}'>#{options[:prompt]}</option>" if options[:include_blank]
    tags << "<option value='-1' #{'selected' if selected == -1 }>ALL</option>" if options[:include_all]
    tags << options_from_collection_for_select(collection, value_method, text_method, selected )
  end

  def code_combined_collection_for_select_tag(name, collection, value_method, text_method, selected = nil, options={})
    defaults = {
      :include_blank => false,
      :prompt => 'Please select',
      :prompt_value => 0,
      :include_all => false
    }
    options = defaults.merge(options)

    option_tags = options_from_collection_for_select_tag(collection, value_method, text_method, selected, options)
    select_tag(name, option_tags.join, :onchange => options[:onchange], :disabled => @readonly)
  end

  def row_state_img_tag(row)
    state = row.created_at > (Date.today - 7) ? 'new' : ''
    
    state.empty? ? '&nbsp;' : image_tag("#{state}.png", :alt => state.capitalize, :class=>"td_state_#{state}")
  end

  def check_box_image_tag(checked = false)
    <<HTML_TAG
<li class='check_box_#{checked}' />
HTML_TAG
  end

  def anchor(div_id)
    <<HTML_TAG
<a id='#{div_id}_anchor' href="##{div_id}_anchor"></a>
HTML_TAG
  end

  #  defaults = {
  #    :mandatory => false,
  #    :unique => false
  #  }
  def field_label_tag(field_descr, options={})
    defaults = {
      :mandatory => false,
      :unique => false,
      :uniq_field_descriptions => nil
    }

    options = defaults.merge(options)

    label_descr = field_descr.to_s.titleize

    if options[:mandatory]
      mandatory_content = '*'.to_html
      mandatory_title = "Must specify #{label_descr}"
    end
    if options[:unique]
      unique_class = 'unique'
      unique_fields = options[:uniq_field_descriptions] || label_descr
      unique_title = "#{unique_fields} must be unique"
    end

    <<HTML_TAG
<span class="mandatory" title="#{mandatory_title}">#{mandatory_content}</span>
<span class="#{unique_class}" title="#{unique_title}">#{label_descr}</span>
HTML_TAG
  end

  
  def select_label_tag(name, selected, text_method = :descr_with_name)
    key = Label.setting_key
        
    vm = VirtualMemory.load(:view_cache, :select_label)
    
    if vm[:key] != key || vm[:collection].nil?
        vm[:key] = key

        labels = Label.find(:all).sort_by{|l| l.send(text_method) }
        vm[:collection] = [['Please select', '']]
        vm[:collection] += labels.collect{|l| [l.send(text_method), l.id]}

        VirtualMemory.store(:view_cache, :select_label, vm)
    end      

    label_options = options_from_collection_for_select_tag(vm[:collection], :last, :first, selected)

    select_tag(name, label_options)
  end
  
  private
  
  def sort_list_options(collection, text_method)
    num = collection.select{|e| e.send(text_method) =~ /^[0-9]/ }
    alpha = collection - num

    num.sort! do |a,b|
      a_value = a.send(text_method)
      b_value = b.send(text_method)

      if a_value.to_f == b_value.to_f
        a_value <=> b_value
      else
        a_value.to_f <=> b_value.to_f
      end

    end

    alpha.sort! do |a,b|
      a_value = a.send(text_method)
      b_value = b.send(text_method)

      a_value <=> b_value
    end

    num + alpha
  end

  # The +:body+ is limited to 1KB
  #
  # See +mail_to+ for more details
  def support_mail_tag(options={})
    defaults = {
      :body => '',
      :subject => nil,
      :cc => nil,
      :bcc => nil,
      :onclick => nil
    }

    options = defaults.merge(options)

    options[:body] = options[:body][0...0x400]
    
    options[:subject] = "[#{Rails.configuration.client_code.upcase}-#{Rails.configuration.system_name.upcase}] #{options[:subject].to_s.titleize}"

    mail_to(
      "PMS Support&lt;#{Rails.configuration.support_email}&gt;", 
      image_tag('mail.png', :alt => 'Send mail', :border => 0, :onclick => options[:onclick]),
      :body => options[:body],
      :subject => options[:subject],
      :cc => options[:cc],
      :bcc => options[:bcc]
    )
  end

  # Load view generated result from #VirtualMemory.
  # If the cached results are older the the object's
  # update_at value, then a block returning the rendered result
  # is required
  #   <%= view_cache(__FILE__, @row, :force => false, :cache_expiration => 60*1) do
  #     render(:partial => 'fetch_row')
  #   end %>
  def view_cache(filename, object, options={})
    defaults = {
      :force => false,
      :cache_expiration => Rails.configuration.cache_expiration
    }

    options = defaults.merge(options)

    view_name = File.basename(filename, '.*').underscore
    
    vm = VirtualMemory.load(:view_cache, "#{view_name}_#{object.id}")
    
    VirtualMemory.check_expiration(vm, 86400) #~ 60*60*24
    
    options[:force] ||= vm[:result].nil? || vm[:env] != Rails.env
    
    if options[:force] || vm[:updated_at] < object.updated_at
      vm[:result] = yield
      vm[:result].gsub!(/(\s)\s+/, '\1')
      vm[:env] = Rails.env
      
      VirtualMemory.store(:view_cache, :"#{view_name}_#{object.id}", vm)
    end
    
    vm[:result]
  end
end
