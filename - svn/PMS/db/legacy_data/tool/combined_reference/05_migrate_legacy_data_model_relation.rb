cr_common_dir = File.join(Rails.root, 'db/legacy_data/tool/combined_reference', 'common')

require cr_common_dir

def up
  msg("Importing Model Relation Records")

  last_product_serie_code = ""
  last_model_serie_code = ""

  dup_values = validate_unique(legacy_data_folder(@file_no), [0,2])
  raise "dup_values is #{dup_values.to_yaml}" unless dup_values.empty?

  model_relate_screen = screen_by_name("MODEL_RELATION")

  ps_custom_field = custom_field_by_name("Product_Series_REF")
  scr_custom_field = custom_field_by_name("SCR_Model_Series")

  ccr_custom_field = custom_field_by_name("CCR_Model_Series_Main")
  
  part_source_field = Field.find(CustomFields::CodeCombindedReference.field_ocr_field_id(custom_field_by_name("CCR_Model_Series_Part").fields.first.value)) #option_combined_ref

  purge_lost_ccr_links(model_relate_screen,
    scr_custom_field.fields.collect{|f| f.screen },
    ccr_custom_field)

  main_ps_row = nil
  model_serie_row = nil
  part_row = nil
  master_data_rows = {}
  scr_rows = {}
  part_ocr_cells = nil

  model_serie_code = ""
  part_code = ""
  scr_code_reqexp = //

  ps_row_ids = ps_custom_field.screen.row_ids
  ps_row_ids.each do |ps_row_id|
    scr_rows[ps_row_id] = CustomFields::ScreenCombindedReference.find_all_rows(scr_custom_field, { ps_custom_field.id => ps_row_id })
  end

  scr_codes = scr_rows.values.collect{|v| v.keys.select{|k| k.is_a?(String)}}.flatten.uniq.sort{|a, b| b <=> a }

  scr_code_reqexp = /^(#{scr_codes.join('|')})/

  part_ps_row = production_serie_by_name("ACC")

  i = 0
  legacy_data(legacy_data_folder(@file_no), true) do |model_serie_spec, group, part_spec, file_name|
    fields = [model_serie_spec, group, part_spec, file_name].compact

    raise "Invalid file format" if fields.size != 4

    product_serie_code = File.basename(file_name).split(/[-\.]/)[3]
    model_serie_code = File.basename(file_name).split(/[-\.]/)[4]

    if (last_product_serie_code != product_serie_code) ||
        (last_model_serie_code != model_serie_code)

      puts "+ #{product_serie_code}:#{model_serie_code}"

      last_product_serie_code = product_serie_code
      last_model_serie_code = model_serie_code

      main_ps_row = production_serie_by_name(product_serie_code)

      raise "Missing Product Serie '#{product_serie_code}'" if main_ps_row.nil?

      model_serie_code = model_serie_spec.gsub(scr_code_reqexp, '\1|').split('|').first

      model_serie_row = scr_rows[main_ps_row.id][model_serie_code]
      
      raise "Missing Model Serie '#{model_serie_code}'" if model_serie_row.nil?

      part_code = part_spec.gsub(scr_code_reqexp, '\1|').split('|').first
      
      part_row = scr_rows[part_ps_row.id][part_code]
      
      raise "Missing Model Serie '#{part_code}'" if part_row.nil?

      master_data_rows[main_ps_row.id] = CustomFields::OptionCombindedReference.find_all_rows(model_serie_row, { ps_custom_field.id => main_ps_row.id })
      master_data_rows[part_ps_row.id] = CustomFields::OptionCombindedReference.find_all_rows(part_row, { ps_custom_field.id => part_ps_row.id })

      reset_ccr_once(model_relate_screen, model_serie_row, ccr_custom_field)

      part_ocr_cells = CustomFields::CodeCombindedReference.option_combined_reference_values(part_row.id, part_source_field.screen_id, part_source_field.custom_field_id)
    end

    model_serie_spec.gsub!(/^#{model_serie_code}/, '')
    part_spec.gsub!(/^#{part_code}/, '')

    row_model = "#{model_relate_screen.prefix}_row".classify.constantize
    row = row_model.new(:screen_id => model_relate_screen.id, :remark => [model_serie_spec[0..100], group, part_spec[0..100]].join(', ')[0..254])

    raise "Invalid data_format" unless CustomFields::CodeCombindedReference.is_valid?(model_serie_spec)
    raise "Invalid data_format" unless CustomFields::CodeCombindedReference.is_valid?(part_spec)

    main_ccr_value = CustomFields::CodeCombindedReference.parse(model_serie_row, model_serie_spec, master_data_rows[main_ps_row.id], scr_rows[main_ps_row.id])

    raise main_ccr_value[:error_messages].inspect if main_ccr_value.has_key?(:error_messages)
    
    part_ccr_value = CustomFields::CodeCombindedReference.parse(part_row, part_spec, master_data_rows[part_ps_row.id], scr_rows[part_ps_row.id])
    
    raise part_ccr_value[:error_messages].inspect if part_ccr_value.has_key?(:error_messages)

    selected_part_options = CustomFields::CodeCombindedReference.cell_selecteds(part_ccr_value).flatten.collect{|h| h[:row_id]}

    test_text_to_search = selected_part_options.join("-")
    index = selected_part_options.size

    part_ocr_cells.each do |c|
      match = !c.regexp(index).match(test_text_to_search).nil?
      part_ccr_value[:ocr_row_id] = c.row_id if match
      break if part_ccr_value[:ocr_row_id]
    end

    group = group.to_s.strip
    group = "Unknown" if group.empty?

    cell_attributes = [
      { :field_id => custom_field_by_name("Product_Series_REF").id, :value => { :row_id => main_ps_row.id } },
      { :field_id => custom_field_by_name("Model Group").id, :value => group },
      { :field_id => custom_field_by_name("CCR_Model_Series_Main").id, :value => main_ccr_value },
      { :field_id => custom_field_by_name("CCR_Model_Series_Part").id, :value => part_ccr_value }
    ]

    row.check_unique = false

    save(row, cell_attributes)

    line_progress(i+=1)
  end
end

begin
  puts ""

  @file_no = '05'

  reset_cache

  up

  puts "Done"
end