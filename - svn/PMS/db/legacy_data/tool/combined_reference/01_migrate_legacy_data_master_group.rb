cr_common_dir = File.join(Rails.root, 'db/legacy_data/tool/combined_reference', 'common')
        
require cr_common_dir

def screen_attributes(screen_name)
  {
    :name => screen_name,
    :display_seq => 0,
    :system => 0,
    :action => "show",
    :controller => "screens"
  }
end

def new_field(field_attributes, custom_field_name)
  Fields::Data.create(field_attributes.update(:custom_field_id => custom_field_by_name(custom_field_name).id ))
end

def new_fields
  [
    new_field(field_attributes_product_serie_code(), "Product_Series_REF"),
    new_field(field_attributes_master_data_code(), "Name"),
    new_field(field_attributes_master_data_descr(), "Descr")
  ]
end

def field_attributes_product_serie_code
  {
    :name => "PRODUCT_SERIE_CODE",
    :display_seq => 1,
    :mandatory_check => 1,
    :unique => 1,
    :sorting_order => 'asc',
    :display_flags  => {
      "250" => true,
      "-1" => false,
      "408" => true,
      "30" => true
    }
  }
end

def field_attributes_master_data_descr
  {
    :name => "MASTER_DATA_DESCR",
    :display_seq => 3,
    :mandatory_check => 0,
    :unique => 0,
    :sorting_order => 'asc',
    :display_flags => {
      "250" => true,
      "-1" => false,
      "408" => true,
      "30" => true
    }
  }
  
end

def field_attributes_master_data_code
  {
    :name => "MASTER_DATA_CODE",
    :display_seq => 2,
    :mandatory_check => 1,
    :unique => 1,
    :sorting_order => 'asc',
    :display_flags => {
      "250" => true,
      "-1" => false,
      "363" => true,
      "408" => true,
      "30" => true
    }
  }
end

def up
  msg("Create Master Data Screens")

  permission_attributes = {
    :role_id => Role.find(:first, :conditions => { :roles => { :name => "Admin" } } ).id
  }

  legacy_data(legacy_data_folder(@file_no), true) do |screen_name, screen_descr|
    screen_name = sanitize_to_id(screen_name).upcase

    puts "+ #{screen_name}"

    screen = screen_by_name(screen_name)
    master_screen = model_master_by_screen_name(screen_name)
    
    case master_screen
    when model_masters[:option]
      scr_cf_screen_value_key = :option_screen_ids
    else
      scr_cf_screen_value_key = :screen_ids
    end

    unless screen.nil?
      reset_screen(screen)

      scr_custom_fields.each do |cf|
        cf.value[scr_cf_screen_value_key] = cf.value[scr_cf_screen_value_key].select{|s_id| s_id.to_i != screen.id }
      end
    end
  
    ActiveRecord::Base.transaction do
      label = Label.create(:name => "S_SCR_#{screen_name}")
      label.captions = languages.collect{|l| Caption.create(:name => screen_name.titleize, :language_id => l.id )}

      screen = ListScreen.new(screen_attributes(screen_name))

      screen.screen = master_screen
      screen.label = label
      screen.fields = new_fields

      screen.save
      
      scr_custom_fields.each do |cf|
        cf.value[scr_cf_screen_value_key] << screen.id
      end

      permission_attributes.update(
        :all => :true,
        :screen_id => screen.id
      )
      
      Permission.create_permissions(Permissions::RoleScreen, permission_attributes)
    end
  end
  
  scr_custom_fields.each do |cf|
    cf.save
  end
end

begin
  puts ""
  
  @file_no = '01'

  reset_cache
  
  up

  puts "Done"
end