require 'test_helper'

class CustomFields::DateTimeFieldTest < ActiveSupport::TestCase

  fixtures :cells, :custom_fields
  
  def test_cell_date
    assert_equal "2011-08-18".to_date, CustomFields::DateTimeField.cell_date(cells(:cell_1267))
    assert_equal Date.null_date, CustomFields::DateTimeField.cell_date(nil)
  end

  def test_check_date_in_range?
    assert_equal true, CustomFields::DateTimeField.check_date_in_range?(cells(:cell_1267).value, "2011-08-30".to_date, "2011-08-01".to_date)
    assert_equal false, CustomFields::DateTimeField.check_date_in_range?(nil, "2011-08-30".to_date, "2011-08-01".to_date)
    assert_equal true, CustomFields::DateTimeField.check_date_in_range?(nil, Date.null_date, Date.null_date)
  end

  def test_month_description
    assert_equal "Jan", CustomFields::DateTimeField.month_description(1)
    assert_equal "Feb", CustomFields::DateTimeField.month_description(2)
  end

  def test_month_year
    assert_equal 8, CustomFields::DateTimeField.month_year(cells(:cell_1267).value)
  end

  def test_quarter_year
    assert_equal 3, CustomFields::DateTimeField.quarter_year(cells(:cell_1267).value)
  end

  def test_half_year
    assert_equal 2, CustomFields::DateTimeField.half_year(cells(:cell_1267).value)
  end

  def test_format_date
    assert_equal :short_date, custom_fields(:custom_fields_date_time_field_21).format_date
  end

  def test_text
    assert_equal "18/08/2011", custom_fields(:custom_fields_date_time_field_21).text(cells(:cell_1267).value)
  end

  def test_default_value
    assert_equal "current_date", custom_fields(:custom_fields_date_time_field_21).default_value
  end

  def test_evaluate_default_value
    assert_equal Time.now, custom_fields(:custom_fields_date_time_field_21).evaluate_default_value()
  end

end
