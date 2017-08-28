require 'test_helper'

class CustomFields::NumericFieldTest < ActiveSupport::TestCase

  fixtures :custom_fields, :cells, :labels

  def test_cleanse_all
    assert_equal [[], []], CustomFields::NumericField.cleanse_all
  end

  def test_cleanse
    assert_equal [], CustomFields::NumericField.cleanse(custom_fields(:custom_fields_numeric_field_20))
  end

  def test_validate_value
    assert_equal 100, CustomFields::NumericField.validate_value(cells(:cell_618).value)
    assert_equal 100, CustomFields::NumericField.validate_value("100.00")
    assert_equal 100.5, CustomFields::NumericField.validate_value("100.50")
    assert_nil CustomFields::NumericField.validate_value("")
    assert_nil CustomFields::NumericField.validate_value(nil)
  end

  def test_ceil
    assert_equal 10.1, CustomFields::NumericField.ceil(10.1, 1)
    assert_equal 10.9, CustomFields::NumericField.ceil(10.9, 1)
    assert_equal 10.1, CustomFields::NumericField.ceil(10.01, 1)
    assert_equal 10.1, CustomFields::NumericField.ceil(10.09, 1)
    assert_equal 10.10, CustomFields::NumericField.ceil(10.1, 2)
    assert_equal 10.90, CustomFields::NumericField.ceil(10.9, 2)
    assert_equal 10.01, CustomFields::NumericField.ceil(10.01, 2)
    assert_equal 10.09, CustomFields::NumericField.ceil(10.09, 2)
  end

  def test_ceil_to
    assert_equal 10.1, CustomFields::NumericField.ceil_to(10.1, 0.1)
    assert_equal 10.9, CustomFields::NumericField.ceil_to(10.9, 0.1)
    assert_equal 10.1, CustomFields::NumericField.ceil_to(10.01, 0.1)
    assert_equal 10.1, CustomFields::NumericField.ceil_to(10.09, 0.1)
    assert_equal 10.10, CustomFields::NumericField.ceil_to(10.1, 0.01)
    assert_equal 10.90, CustomFields::NumericField.ceil_to(10.9, 0.01)
    assert_equal 10.01, CustomFields::NumericField.ceil_to(10.01, 0.01)
    assert_equal 10.09, CustomFields::NumericField.ceil_to(10.09, 0.01)
  end

  def test_floor
    assert_equal 10.1, CustomFields::NumericField.floor(10.1, 1)
    assert_equal 10.9, CustomFields::NumericField.floor(10.9, 1)
    assert_equal 10.0, CustomFields::NumericField.floor(10.01, 1)
    assert_equal 10.0, CustomFields::NumericField.floor(10.09, 1)
    assert_equal 10.1, CustomFields::NumericField.floor(10.1, 2)
    assert_equal 10.9, CustomFields::NumericField.floor(10.9, 2)
    assert_equal 10.01, CustomFields::NumericField.floor(10.01, 2)
    assert_equal 10.09, CustomFields::NumericField.floor(10.09, 2)
  end

  def test_floor_to
    assert_equal 10.1, CustomFields::NumericField.floor_to(10.1, 0.1)
    assert_equal 10.9, CustomFields::NumericField.floor_to(10.9, 0.1)
    assert_equal 10.0, CustomFields::NumericField.floor_to(10.01, 0.1)
    assert_equal 10.0, CustomFields::NumericField.floor_to(10.09, 0.1)
    assert_equal 10.10, CustomFields::NumericField.floor_to(10.1, 0.01)
    assert_equal 10.90, CustomFields::NumericField.floor_to(10.9, 0.01)
    assert_equal 10.01, CustomFields::NumericField.floor_to(10.01, 0.01)
    assert_equal 10.09, CustomFields::NumericField.floor_to(10.09, 0.01)
  end

  def test_round
    assert_equal 10.1, CustomFields::NumericField.round(10.1, 1)
    assert_equal 10.9, CustomFields::NumericField.round(10.9, 1)
    assert_equal 10.0, CustomFields::NumericField.round(10.01, 1)
    assert_equal 10.1, CustomFields::NumericField.round(10.09, 1)
    assert_equal 10.10, CustomFields::NumericField.round(10.1, 2)
    assert_equal 10.90, CustomFields::NumericField.round(10.9, 2)
    assert_equal 10.01, CustomFields::NumericField.round(10.01, 2)
    assert_equal 10.09, CustomFields::NumericField.round(10.09, 2)
  end

  def test_round_to
    assert_equal 10.1, CustomFields::NumericField.round_to(10.1, 0.1)
    assert_equal 10.9, CustomFields::NumericField.round_to(10.9, 0.1)
    assert_equal 10.0, CustomFields::NumericField.round_to(10.01, 0.1)
    assert_equal 10.1, CustomFields::NumericField.round_to(10.09, 0.1)
    assert_equal 10.10, CustomFields::NumericField.round_to(10.1, 0.01)
    assert_equal 10.90, CustomFields::NumericField.round_to(10.9, 0.01)
    assert_equal 10.01, CustomFields::NumericField.round_to(10.01, 0.01)
    assert_equal 10.09, CustomFields::NumericField.round_to(10.09, 0.01)
  end

  def test_apply_format_option
    custom_field = custom_fields(:custom_fields_numeric_field_20)
    assert_equal 10.00, CustomFields::NumericField.apply_format_option(10, :number, custom_field.option)
    assert_equal "10.10", CustomFields::NumericField.apply_format_option(10.1, custom_field.format, custom_field.option)
    assert_equal "10.90", CustomFields::NumericField.apply_format_option(10.9, custom_field.format, custom_field.option)
  end

  def test_validate_value
    assert_equal 10.0, custom_fields(:custom_fields_numeric_field_20).validate_value("10")
    assert_equal 10.0, custom_fields(:custom_fields_numeric_field_20).validate_value("10.0")
    assert_equal 10, custom_fields(:custom_fields_numeric_field_20).validate_value("10.00")
    assert_equal 10.00, custom_fields(:custom_fields_numeric_field_20).validate_value("10.000")
    assert_nil custom_fields(:custom_fields_numeric_field_20).validate_value("")
    assert_nil custom_fields(:custom_fields_numeric_field_20).validate_value(nil)
  end

  def test_absolute_value
    assert_equal 10.0, custom_fields(:custom_fields_numeric_field_20).absolute_value("10")
    assert_equal 10.0, custom_fields(:custom_fields_numeric_field_20).absolute_value("10.0")
    assert_equal 10, custom_fields(:custom_fields_numeric_field_20).absolute_value("10.00")
    assert_equal 10.00, custom_fields(:custom_fields_numeric_field_20).absolute_value("10.000")
    assert_nil custom_fields(:custom_fields_numeric_field_20).absolute_value("")
    assert_nil custom_fields(:custom_fields_numeric_field_20).absolute_value(nil)
  end

  def test_default_value
    assert_equal 0.0, custom_fields(:custom_fields_numeric_field_20).default_value
  end

  def test_format
    assert_equal :number, custom_fields(:custom_fields_numeric_field_20).format
  end

  def test_option
    assert_equal({:rounding=>:None,  :significance=>1.0,  :prefix_multiplier=>:None,  :delimiter=>",",  :separator=>".",  :unit=>:USD,  :precision=>2}, custom_fields(:custom_fields_numeric_field_20).option)
  end

  def test_label_descr
    assert_equal "Numeric Field 1", custom_fields(:custom_fields_numeric_field_20).label_descr
  end

  def test_display_label_descr
    assert_equal "Numeric Field 1", custom_fields(:custom_fields_numeric_field_20).display_label_descr
  end

  def test_text
    assert_equal "50.00", custom_fields(:custom_fields_numeric_field_20).text(cells(:cell_617).value)
  end

  def test_html
    assert_equal "50.00", custom_fields(:custom_fields_numeric_field_20).html(cells(:cell_617).value)
  end
end
