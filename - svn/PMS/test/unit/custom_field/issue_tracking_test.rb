require 'test_helper'

class CustomFields::IssueTrackingTest < ActiveSupport::TestCase

  fixtures :custom_fields, :cells

  def test_cancelled?
    assert_equal false, CustomFields::IssueTracking.cancelled?(cells(:cell_352).value)
    assert_equal false, CustomFields::IssueTracking.cancelled?(nil)
  end

  def test_absolute_value
    assert_equal [:delayed, "2011-06-28".to_date], custom_fields(:custom_fields_issue_tracking_49).absolute_value(cells(:cell_352).value)
    assert_equal [:unscheduled, Date.null_date], custom_fields(:custom_fields_issue_tracking_49).absolute_value(nil)
  end

  def test_text
    assert_equal "[Delayed] 2011-06-28", custom_fields(:custom_fields_issue_tracking_49).text(cells(:cell_352).value)
    assert_equal "[Unscheduled] ----/--/--", custom_fields(:custom_fields_issue_tracking_49).text(nil)
  end

  def test_default_value
    assert_equal "current_date", custom_fields(:custom_fields_issue_tracking_49).default_value
  end

end
