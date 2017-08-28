require 'test_helper'

class CustomFields::DateTimeRangeTest < ActiveSupport::TestCase

  fixtures :custom_fields, :cells, :date_time_range_values

  def test_format_date
    assert_equal :short_date, custom_fields(:custom_fields_date_time_range_68).format_date
  end

  def test_default_value
    assert_equal "current_date", custom_fields(:custom_fields_date_time_range_68).default_value
  end

  def test_html
    assert_equal "From: 01/01/2001 - To: 01/04/2005", custom_fields(:custom_fields_date_time_range_68).html(cells(:cell_1266))
  end

  def test_text
    assert_equal "", custom_fields(:custom_fields_date_time_range_68).text({})
    assert_equal "", custom_fields(:custom_fields_date_time_range_68).text(nil)
    assert_equal "", custom_fields(:custom_fields_date_time_range_68).text("")
    assert_equal "From: 2000-01-01 - To: 2005-01-04", custom_fields(:custom_fields_date_time_range_68).text({:form => "01/01/2001", :to => "01/04/2005"})
  end

end
