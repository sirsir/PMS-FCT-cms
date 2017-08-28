require 'test_helper'

class CustomFields::DateTimeFormatTest < ActiveSupport::TestCase

  fixtures :cells

  def test_date_options_collection
    assert_equal [], CustomFields::DateTimeFormat.date_options_collection
  end

#  def test_find_by_name
#    assert_equal
#  end

end
