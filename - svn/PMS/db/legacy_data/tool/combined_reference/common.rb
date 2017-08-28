common_dir = File.join(Rails.root, 'db/legacy_data/tool', 'common')

require common_dir

def legacy_data_folder(folder_no)
  %w(
    combined_reference/01-master_group
    combined_reference/02-master_data
    combined_reference/03-model_serie
    combined_reference/04-model_specification
    combined_reference/05-model_relation
    combined_reference/06-model_option
  )[folder_no.to_s.to_i - 1]
end

def model_masters
  @cache_model_masters ||= {
    :general => screen_by_name("ScreenMaster_Model"),
    :option => screen_by_name("ScreenMaster_Model Option"),
    :accessory => screen_by_name("ScreenMaster_Model Accessory")
  }
end

def scr_custom_fields
  @cache_scr_custom_fields ||= combined_reference_custom_fields.select{|cf|
    cf.is_a?(CustomFields::ScreenCombindedReference)
  }
end

def ocr_custom_fields
  @cache_ocr_custom_fields ||= combined_reference_custom_fields.select{|cf|
    cf.is_a?(CustomFields::OptionCombindedReference)
  }
end

def ccr_custom_fields
  @cache_ccr_custom_fields ||= combined_reference_custom_fields.select{|cf|
    cf.is_a?(CustomFields::CodeCombindedReference)
  }
end

def combined_reference_custom_fields
  @cache_combined_reference_custom_fields ||= CustomField.find(:all).select{|cf|
    cf.is_a?(CustomFields::ScreenCombindedReference) ||
      cf.is_a?(CustomFields::OptionCombindedReference) ||
      cf.is_a?(CustomFields::CodeCombindedReference)
  }
end

def model_master_by_screen_name(screen_name)
  screen_name = screen_name.to_s.strip

  if screen_name =~ /_ACC_/i
    model_masters[:accessory]
  elsif screen_name =~ /_OPTION$/i
    model_masters[:option]
  else
    model_masters[:general]
  end
end

def reset_screen(screen)
  ActiveRecord::Base.transaction do
    reset_screen_once(screen)

    screen.label.destroy

    screen.destroy
  end
end

def reset_rows(row_ids)
  conn = ActiveRecord::Base.connection
  
  row_ids = [-1, row_ids].flatten.join(',')
  conn.delete <<SQL_CMD
  DELETE FROM cells WHERE row_id IN (#{row_ids})
SQL_CMD
  
  conn.delete <<SQL_CMD
  DELETE FROM full_logs WHERE row_id IN (#{row_ids})
SQL_CMD

  conn.delete <<SQL_CMD
  DELETE FROM rows WHERE id IN (#{row_ids})
SQL_CMD
end

def reset_screen_once(screen)
  @cache_reseted_screens ||= []

  unless @cache_reseted_screens.include?(screen.name)
    @cache_reseted_screens << screen.name

    if screen.row_ids.size > 0
      puts "- #{screen.name} #{screen.row_ids.size} record(s)"

      reset_rows(screen.row_ids)
    end
  end
end

def production_serie_by_name(production_serie_code)
  reference_by_code("Product_Series_REF", production_serie_code)
end

def reset_cache
  reset_common_cache
  
  @cache_model_masters = nil
  @cache_scr_custom_fields = nil
  @cache_ocr_custom_fields = nil
  @cache_ccr_custom_fields = nil
  @cache_combined_reference_custom_fields = nil
  @cache_reseted_screens = nil
end

def reset_ccr_once(screen, scr_row, ccr_custom_field)
  @reset_ccr_once ||= []

  unless @reset_ccr_once.include?(scr_row.id)
    @reset_ccr_once << scr_row.id

    rows = screen.rows.select{|r| CustomFields::CodeCombindedReference.cell_scr_row_id(r.cell(ccr_custom_field.id).value) == scr_row.id }

    puts "- #{scr_row.description} #{rows.size} record(s)"

    reset_rows(rows.collect{|r| r.id })
  end
end

def purge_lost_ccr_links(ccr_screen, scr_screens, ccr_custom_field)
  scr_row_ids = scr_screens.collect{|s| s.row_ids }.flatten
  rows = ccr_screen.rows.select{|r|
    !scr_row_ids.include?(CustomFields::CodeCombindedReference.cell_scr_row_id(r.cell(ccr_custom_field.id).value))
  }

  puts "- #{ccr_screen.name} #{rows.size} record(s)"

  reset_rows(rows.collect{|r| r.id })
end
