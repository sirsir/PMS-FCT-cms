require 'test_helper'

class CustomFields::TextFieldTest < ActiveSupport::TestCase

  fixtures :custom_fields

  def test_default_value
    assert_equal "", custom_fields(:custom_fields_text_field_1).default_value
  end

  def test_alphabet
    assert_equal "all", custom_fields(:custom_fields_text_field_1).alphabet
  end

  def test_numeric
    assert_equal "true", custom_fields(:custom_fields_text_field_1).numeric
  end

  def test_symbols
    assert_equal ["-1"], custom_fields(:custom_fields_text_field_1).symbols
  end

  def test_min_length
    assert_equal "0", custom_fields(:custom_fields_text_field_1).min_length
  end

  def test_max_length
    assert_equal "50", custom_fields(:custom_fields_text_field_1).max_length
  end

  def test_option
    assert_equal({:numeric=>"true",  :symbols=>[],  :alphabet=>"all",  :length=>{:max=>"50", :min=>"0"}}, custom_fields(:custom_fields_text_field_1).option)
  end

end

class CustomFields::NoneAlphaNumericTest < ActiveSupport::TestCase

  def test_find
    assert_nil CustomFields::NoneAlphaNumeric.find("")
    assert_nil CustomFields::NoneAlphaNumeric.find(nil)
  end

end