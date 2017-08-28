require 'test_helper'

class CustomFields::ComboBoxTest < ActiveSupport::TestCase
  
  def test_cell_label_id
    assert_equal 1, CustomFields::ComboBox.cell_label_id("1")
    assert_equal 0, CustomFields::ComboBox.cell_label_id(nil)
  end
  
end
