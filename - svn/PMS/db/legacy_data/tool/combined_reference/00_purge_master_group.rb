cr_common_dir = File.join(Rails.root, 'db/legacy_data/tool/combined_reference', 'common')
        
require cr_common_dir

def up
  msg("Dropping Master Data Screens")

  model_masters.values.each do |ms|
    ms.childs.each do |s|
      reset_screen(s)
    end
  end

  combined_reference_custom_fields.each do |cf|
    cf.fields.each do |f|
      reset_screen_once(f.screen)
    end
  end

  scr_custom_fields.each do |cf|
    cf.value[:screen_ids] = [-1]
    cf.value[:option_screen_ids] = [-1]

    cf.save
  end
end

def down
  
end

begin
  puts ""
  
  @file_no = '00'

  down
  
  up

  puts "Done"
end