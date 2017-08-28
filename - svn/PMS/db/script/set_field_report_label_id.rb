begin
  puts ""
  
  fields_reports = FieldsReport.find(:all)
  puts "Loaded #{fields_reports.size} records"
  
  row_fields_reports = fields_reports.select{|fr| fr.location == :row }
  puts "Got #{row_fields_reports.size} rows"
  
  data_fields_reports = row_fields_reports.select{|fr| fr.field.is_a?(Fields::Data) }
  puts "Got #{data_fields_reports.size} datas"
  
  text_fields_reports = data_fields_reports.select{|fr| fr.field.custom_field.is_a?(CustomFields::TextField) }
  puts "Got #{text_fields_reports.size} texts"
  
  name_fields_reports = text_fields_reports.select{|fr| fr.field.custom_field.name =~ /name/i }
  puts "Got #{name_fields_reports.size} names"
  
  name_fields_reports.each do |fr|
    fr.label_id = fr.field.screen.label_id
    
    fr.save
  end
  
  puts "Done"
end