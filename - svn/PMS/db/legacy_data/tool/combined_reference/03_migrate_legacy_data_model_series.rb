cr_common_dir = File.join(Rails.root, 'db/legacy_data/tool/combined_reference', 'common')

require cr_common_dir

def reset_model_serie_once(screen, rf_row)
  @reseted_model_series ||= []

  unless @reseted_model_series.include?(rf_row.id)
    @reseted_model_series << rf_row.id

    ps_custom_field = custom_field_by_name("Product_Series_REF")

    rows = screen.rows.select{|r| CustomFields::Reference.cell_ref_row_id(r.cell(ps_custom_field.id).value) == rf_row.id }

    puts "- #{rf_row.description} #{rows.size} record(s)"

    reset_rows(rows.collect{|r| r.id })
  end
end

def up
  msg("Importing Model Serie Records")

  last_product_serie_code = ""

  dup_values = validate_unique(legacy_data_folder(@file_no), [0,1])
  raise "dup_values is #{dup_values.to_yaml}" unless dup_values.empty?

  ms_screen = screen_by_name("MODEL_SERIES")
  ps_row = nil

  i = 0

  legacy_data(legacy_data_folder(@file_no), true) do |product_serie_code, model_serie_code, model_serie_descr, data_format|
    
    puts "+ #{product_serie_code}" if last_product_serie_code != product_serie_code
    
    ps_row = production_serie_by_name(product_serie_code)
    
    raise "Missing Product Serie '#{product_serie_code}'" if ps_row.nil?
    
    reset_model_serie_once(ms_screen, ps_row)

    last_product_serie_code = product_serie_code

    ps_custom_field = custom_field_by_name("Product_Series_REF")

    scr_custom_field = CustomFields::ScreenCombindedReference.find(:first)
    scr_rows = CustomFields::ScreenCombindedReference.find_all_rows(scr_custom_field, { ps_custom_field.id => ps_row.id })

    row_model = "#{ms_screen.prefix}_row".classify.constantize
    row = row_model.new(:screen_id => ms_screen.id, :remark => data_format[0..254])

    raise "Invalid data_format" unless CustomFields::ScreenCombindedReference.is_valid?(data_format)

    scr_value = CustomFields::ScreenCombindedReference.parse(model_serie_code, data_format, scr_rows)

    if scr_value.has_key?(:error_messages)
      raise scr_value[:error_messages].inspect
    end

    model_serie_descr = "#{model_serie_code}'s Description" if model_serie_descr.empty?

    cell_attributes = [
      { :field_id => custom_field_by_name("Product_Series_REF").id, :value => { :row_id => ps_row.id } },
      { :field_id => custom_field_by_name("SCR_Model_Series").id, :value => scr_value },
      { :field_id => custom_field_by_name("Descr").id, :value => model_serie_descr }
    ]

    row.check_unique = false

    save(row, cell_attributes)
    
    line_progress(i+=1)
  end
end

begin
  puts ""

  @file_no = '03'

  reset_cache

  up

  puts "Done"
end