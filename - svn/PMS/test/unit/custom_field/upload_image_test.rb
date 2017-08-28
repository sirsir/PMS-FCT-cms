require 'test_helper'

class CustomFields::UploadImageTest < ActiveSupport::TestCase
  
  fixtures :custom_fields

  def test_description
    assert_equal "Upload Image jpg, gif, png <=250 KB", custom_fields(:custom_fields_upload_image_24).description
  end

  def test_file_type
    assert_equal({"jpg"=>"true", "-1"=>"false", "gif"=>"true", "png"=>"true"}, custom_fields(:custom_fields_upload_image_24).file_type)
  end

  def test_max_size
    assert_equal "250", custom_fields(:custom_fields_upload_image_24).max_size
  end

  def test_dimensions
    assert_equal "0x0", custom_fields(:custom_fields_upload_image_24).dimensions
  end

  def test_option
    assert_equal({"file_type"=>{"jpg"=>"true", "-1"=>"false", "gif"=>"true", "png"=>"true"},  "dimensions"=>"0x0",  "max_size"=>"250"}, custom_fields(:custom_fields_upload_image_24).option)
  end

end