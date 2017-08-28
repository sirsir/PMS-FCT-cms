cr_common_dir = File.join(Rails.root, 'db/legacy_data/tool/combined_reference', 'common')

require cr_common_dir

def up
  msg("Importing Model Option Records")

  last_product_serie_code = ""
  last_model_serie_code = ""

  dup_values = validate_unique(legacy_data_folder(@file_no), [0,1])
  raise "dup_values is #{dup_values.to_yaml}" unless dup_values.empty?

  model_option_screen = screen_by_name("MODEL_OPTION")

  ps_custom_field = custom_field_by_name("Product_Series_REF")
  scr_custom_field = custom_field_by_name("SCR_Model_Series")

  ccr_custom_field = custom_field_by_name("CCR_Model_Series_Main")

  purge_lost_ccr_links(model_option_screen,
    scr_custom_field.fields.collect{|f| f.screen },
    ccr_custom_field)

  main_ps_row = nil
  model_serie_row = nil
  master_data_rows = {}
  scr_rows = {}

  model_serie_code = ""
  scr_code_reqexp = //

  ps_row_ids = ps_custom_field.screen.row_ids
  ps_row_ids.each do |ps_row_id|
    scr_rows[ps_row_id] = CustomFields::ScreenCombindedReference.find_all_rows(scr_custom_field, { ps_custom_field.id => ps_row_id })
  end

  scr_codes = scr_rows.values.collect{|v| v.keys.select{|k| k.is_a?(String)}}.flatten.uniq.sort{|a, b| b <=> a }

  scr_code_reqexp = /^(#{scr_codes.join('|')})/

  i = 0
  legacy_data(legacy_data_folder(@file_no), true) do |model_serie_spec, option_group, std_price, fob, file_name|
    fields = [model_serie_spec, option_group, std_price, fob, file_name].compact

    raise "Invalid file format" if fields.size != 5

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

      master_data_rows[main_ps_row.id] = CustomFields::OptionCombindedReference.find_all_rows(model_serie_row, { ps_custom_field.id => main_ps_row.id })

      reset_ccr_once(model_option_screen, model_serie_row, ccr_custom_field)
    end

    model_serie_spec.gsub!(/^#{model_serie_code}/, '')

    row_model = "#{model_option_screen.prefix}_row".classify.constantize
    row = row_model.new(:screen_id => model_option_screen.id, :remark => [model_serie_spec[0..100], option_group, std_price, fob].join(', ')[0..254])

    raise "Invalid data_format" unless CustomFields::CodeCombindedReference.is_valid?(model_serie_spec)

    main_ccr_value = CustomFields::CodeCombindedReference.parse(model_serie_row, model_serie_spec, master_data_rows[main_ps_row.id], scr_rows[main_ps_row.id])

    raise main_ccr_value[:error_messages].inspect if main_ccr_value.has_key?(:error_messages)

    opt_row = nil
    
    option_codes = option_group.gsub(/(\[.+?\])/, '|\1').split('|')
    option_code = option_codes.first
    screen_code = option_codes.last if option_codes.size > 1
    
    if screen_code.nil?
      option_screen_ids = model_serie_row.screen_combined_option_screen_ids
    else
      option_screen = screen_by_name(screen_code.gsub(/[\[\]]/, ''))

      raise "Missing Option Screen '#{screen_code}'" if option_screen.nil?

      option_screen_ids = [option_screen.id]
    end
    
    option_screen_ids.each do |s_id|
      opt_row = master_data_rows[main_ps_row.id][s_id][option_code]
      break unless opt_row.nil?
    end
    
    raise "Row code '#{main_ps_row.description}':'#{option_group}' wasn't found in the Master Data Cache" if opt_row.nil?

    main_ccr_value[:opt_row_ids] = [opt_row.id]

    cell_attributes = [
      { :field_id => custom_field_by_name("CCR_Model_Series_Main").id, :value => main_ccr_value },
      { :field_id => custom_field_by_name("Base_Std_Price").id, :value => CustomFields::NumericField.validate_value(std_price) },
      { :field_id => custom_field_by_name("Base_FOB_Price").id, :value => CustomFields::NumericField.validate_value(fob) }
    ]

    row.check_unique = false

    save(row, cell_attributes)

    line_progress(i+=1)
  end
end

begin
  puts ""

  @file_no = '06'

  reset_cache

  up

  puts "Done"
end