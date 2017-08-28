require 'test_helper'

class CustomFieldTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_is_used?
    # This method just return boolean
    custom_field = CustomField.find(186)
    custom_field_name = custom_field.name
    assert_not_nil custom_field_name
    assert_kind_of String, custom_field_name 
  end
  
  test "the truth" do
    assert true
  end
end
