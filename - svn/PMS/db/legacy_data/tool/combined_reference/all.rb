%w(
01_migrate_legacy_data_master_group
02_migrate_legacy_data_master_data
03_migrate_legacy_data_model_series
04_migrate_legacy_data_model_specification
05_migrate_legacy_data_model_relation
06_migrate_legacy_data_model_option
).each do |file_name|
  next if file_name =~ /^_/
  
  require File.join(Rails.root, 'db/legacy_data/tool/combined_reference', file_name)
end