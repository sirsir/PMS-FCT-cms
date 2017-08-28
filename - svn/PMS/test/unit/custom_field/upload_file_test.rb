require 'test_helper'

class CustomFields::UploadFileTest < ActiveSupport::TestCase

  fixtures :custom_fields

  def test_description
    assert_equal "Upload File html, xml, txt, csv <=128 KB", custom_fields(:custom_fields_upload_file_56).description
  end

  def test_file_type
    assert_equal({"html"=>"true", "xml"=>"true", "-1"=>"false", "txt"=>"true", "csv"=>"true"}, custom_fields(:custom_fields_upload_file_56).file_type)
  end

  def test_max_size
    assert_equal "128", custom_fields(:custom_fields_upload_file_56).max_size
  end

  def test_option
    assert_equal({"file_type"=>   {"html"=>"true", "xml"=>"true", "-1"=>"false", "txt"=>"true", "csv"=>"true"},  "max_size"=>"128"}, custom_fields(:custom_fields_upload_file_56).option)
  end

end

class CustomFields::FileTypeTest < ActiveSupport::TestCase

  def test_image_type_collection
    assert_equal [], CustomFields::FileType.image_type_collection
  end

end