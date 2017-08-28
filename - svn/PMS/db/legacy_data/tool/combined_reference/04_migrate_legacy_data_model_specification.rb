cr_common_dir = File.join(Rails.root, 'db/legacy_data/tool/combined_reference', 'common')

require cr_common_dir

def reset_model_spec_once(screen, scr_row)
  @reset_model_spec_once ||= []

  unless @reset_model_spec_once.include?(scr_row.id)
    @reset_model_spec_once << scr_row.id

    rows = screen.rows.select{|r| r.option_combined_row_id == scr_row.id }

    puts "- #{scr_row.description} #{rows.size} record(s)"

    reset_rows(rows.collect{|r| r.id })
  end
end

def purge_lost_links(ocr_screen, scr_screens)
  scr_row_ids = scr_screens.collect{|s| s.row_ids }.flatten
  rows = ocr_screen.rows.select{|r| !scr_row_ids.include?(r.option_combined_row_id) }

  puts "- #{ocr_screen.name} #{rows.size} record(s)"

  reset_rows(rows.collect{|r| r.id })
end

def up
  msg("Importing Model Specification Records")

  last_product_serie_code = ""
  last_model_serie_code = ""

  dup_values = validate_unique(legacy_data_folder(@file_no), [0,1])
  raise "dup_values is #{dup_values.to_yaml}" unless dup_values.empty?
  
  model_spec_screen = screen_by_name("MODEL_SPECIFICATION")

  ps_custom_field = custom_field_by_name("Product_Series_REF")
  scr_custom_field = custom_field_by_name("SCR_Model_Series")
  
  purge_lost_links(model_spec_screen, scr_custom_field.fields.collect{|f| f.screen })

  ps_row = nil
  model_serie_row = nil
  master_data_rows = {}
  scr_rows = {}

  i = 0
  legacy_data(legacy_data_folder(@file_no), true) do |model_serie_code, model_serie_spec, std_price, fob, file_name|
    fields = [model_serie_code, model_serie_spec, std_price, fob, file_name].compact

    raise "Invalid file format" if fields.size != 5

    product_serie_code = File.basename(file_name).split(/-/)[3]
    
    if (last_product_serie_code != product_serie_code) ||
        (last_model_serie_code != model_serie_code)
      
      puts "+ #{product_serie_code}:#{model_serie_code}"

      last_product_serie_code = product_serie_code
      last_model_serie_code = model_serie_code

      ps_row = production_serie_by_name(product_serie_code)

      raise "Missing Product Serie '#{product_serie_code}'" if ps_row.nil?
      
      scr_rows = CustomFields::ScreenCombindedReference.find_all_rows(scr_custom_field, { ps_custom_field.id => ps_row.id })

      model_serie_row = scr_rows[model_serie_code]

      raise "Missing Model Serie '#{model_serie_code}'" if model_serie_row.nil?

      master_data_rows = CustomFields::OptionCombindedReference.find_all_rows(model_serie_row, { ps_custom_field.id => ps_row.id })
      
      reset_model_spec_once(model_spec_screen, model_serie_row)
    end

    row_model = "#{model_spec_screen.prefix}_row".classify.constantize
    row = row_model.new(:screen_id => model_spec_screen.id, :remark => [model_serie_code[0..100], model_serie_spec[0..100], std_price, fob].join(', ')[0..254])

    raise "Invalid data_format" unless CustomFields::OptionCombindedReference.is_valid?( model_serie_spec)

    ocr_value = CustomFields::OptionCombindedReference.parse(model_serie_row, model_serie_spec, master_data_rows, scr_rows)

    raise ocr_value[:error_messages].inspect if ocr_value.has_key?(:error_messages)

    cell_attributes = [
      { :field_id => custom_field_by_name("Product_Series_REF").id, :value => { :row_id => ps_row.id } },
      { :field_id => custom_field_by_name("OCR_Model_Series").id, :value => ocr_value },
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

  @file_no = '04'

  reset_cache

  up

  puts "Done"
end