require 'test_helper'

class FieldTypeTest < ActiveSupport::TestCase
  # Replace this with your real tests.
   def test_is_used?
    # This method just return boolean
    field_type = FieldType.find( 2 )
    field_type_name = field_type.name
    
    assert_not_nil field_type_name
    assert_kind_of String, field_type_name 
  end
  
  test "the truth" do
    assert true
  end
end
