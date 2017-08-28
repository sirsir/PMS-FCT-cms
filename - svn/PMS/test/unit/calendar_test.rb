require 'test_helper'

class CalendarTest < ActiveSupport::TestCase

  fixtures :cells, :custom_fields, :fields, :screens, :calendar_values

  def test_cell_date
    assert_equal "2010-01-01".to_date, CustomFields::Calendar.cell_date(cells(:cell_358))
    assert_equal Date.null_date, CustomFields::Calendar.cell_date({})
    assert_equal Date.null_date, CustomFields::Calendar.cell_date(nil)
  end

  def test_cell_date_from
    assert_equal "2010-01-01".to_date, CustomFields::Calendar.cell_date_from(cells(:cell_358))
    assert_equal Date.null_date, CustomFields::Calendar.cell_date_from({})
    assert_equal Date.null_date, CustomFields::Calendar.cell_date_from(nil)
  end

  def test_cell_date_to
    assert_equal (("2010-12-31").to_date).end_of_day, CustomFields::Calendar.cell_date_to(cells(:cell_358), custom_fields(:custom_fields_calendar_14))
    assert_equal ((Date.null_date >> 12) - 1).end_of_day, CustomFields::Calendar.cell_date_to({}, nil)
    assert_equal ((Date.null_date >> 12) - 1).end_of_day, CustomFields::Calendar.cell_date_to(nil, nil)
  end

  def test_is_calendar_format?
    calendar = custom_fields(:custom_fields_calendar_14)
    assert_equal true, calendar.is_calendar_format?("monthly")
    assert_equal false, calendar.is_calendar_format?("weekly")
    assert_equal false, calendar.is_calendar_format?(nil)
    assert_equal false, calendar.is_calendar_format?("")
  end

  def test_monthly_format?
    assert_equal true, custom_fields(:custom_fields_calendar_14).monthly_format?
  end

  def test_format
    assert_equal :monthly, custom_fields(:custom_fields_calendar_14).format
  end

  def test_start_of_week
    assert_equal "", custom_fields(:custom_fields_calendar_14).start_of_week
  end
  
  def test_detail_screen_id
    assert_equal 196, custom_fields(:custom_fields_calendar_14).detail_screen_id
  end

  def test_detail_screen
    assert_equal screens(:detail_screen_196), custom_fields(:custom_fields_calendar_14).detail_screen
  end

  def test_get_row_id
    assert_equal "123", custom_fields(:custom_fields_calendar_14).get_row_id("calendar_value_row_123")
  end

  def test_text
    assert_equal "Selected date 2010", custom_fields(:custom_fields_calendar_14).text({:selected_date => "2010-01-01"})
    assert_equal "Selected date 2000", custom_fields(:custom_fields_calendar_14).text({})
  end
end
