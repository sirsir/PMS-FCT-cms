require 'test_helper'

class CustomFields::TextAreaTest < ActiveSupport::TestCase

  fixtures :custom_fields

  def test_default_value
    assert_equal "", custom_fields(:custom_fields_text_area_54).default_value
  end

  def test_alphabet
    assert_equal "all", custom_fields(:custom_fields_text_area_54).alphabet
  end

  def test_numeric
    assert_equal "true", custom_fields(:custom_fields_text_area_54).numeric
  end

  def test_symbols
    assert_equal ["!", "(", ")", "*", "+", ",", "-", ".", "/", "@", "-1"], custom_fields(:custom_fields_text_area_54).symbols
  end

  def test_min_length
    assert_equal "0", custom_fields(:custom_fields_text_area_54).min_length
  end

  def test_max_length
    assert_equal "300", custom_fields(:custom_fields_text_area_54).max_length
  end

end
