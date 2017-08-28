cr_common_dir = File.join(Rails.root, 'db/legacy_data/tool/combined_reference', 'common')

require cr_common_dir

def up
  msg("Importing Master Data Records")

  last_screen_name = ""

  dup_values = validate_unique(legacy_data_folder(@file_no), [0,1,2])
  raise "dup_values is #{dup_values.to_yaml}" unless dup_values.empty?
  
  legacy_data(legacy_data_folder(@file_no), true) do |screen_name, product_serie_code, master_data_code, master_data_descr|
    screen_name = sanitize_to_id(screen_name).upcase

    puts "+ #{screen_name}" if last_screen_name != screen_name
    
    last_screen_name = screen_name

    screen = screen_by_name(screen_name)
    
    if screen.nil?
      raise "Missing Screen '#{screen_name}'"
    else
      reset_screen_once(screen)

      screen.rows.reload
      
      row_model = "#{screen.prefix}_row".classify.constantize
      row = row_model.new(:screen_id => screen.id, :remark => "")

      master_data_descr = "#{master_data_code}'s Description" if master_data_descr.empty?

      cell_attributes = [
        { :field_id => custom_field_by_name("Product_Series_REF").id, :value => { :row_id => production_serie_by_name(product_serie_code).id } },
        { :field_id => custom_field_by_name("Name").id, :value => master_data_code },
        { :field_id => custom_field_by_name("Descr").id, :value => master_data_descr }
      ]

      row.check_unique = false

      save(row, cell_attributes)
    end
  end
end

begin
  puts ""

  @file_no = '02'

  reset_cache

  up

  puts "Done"
end