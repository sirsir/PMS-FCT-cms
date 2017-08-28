require 'test_helper'

class FieldTest < ActiveSupport::TestCase

  def test_missing_msg
    assert_equal "<span class='error_message'>Field with ID=1 is missing!</span>", Field.missing_msg(1)
    assert_equal "<span class='error_message'>Field with ID= is missing!</span>", Field.missing_msg(nil)
  end

  def test_display_numeric_format
    assert_equal "", Field.display_numeric_format
  end

end