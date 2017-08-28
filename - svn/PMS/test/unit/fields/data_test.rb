require 'test_helper'

class Fields::DataTest < ActiveSupport::TestCase
  
  fixtures :fields, :rows

  def test_label_descrs
    assert_equal ["Code"], fields(:fields_data_50).label_descrs(rows(:detail_row_237))
    assert_equal ["Code"], fields(:fields_data_50).label_descrs(nil)
    assert_equal ["Code"], fields(:fields_data_50).label_descrs("")
  end

  def test_screen_ids
    assert_equal [], fields(:fields_data_50).screen_ids
    assert_equal [], fields(:fields_data_16).screen_ids
  end

  def test_screens
    assert_equal [], fields(:fields_data_50).screens
    assert_equal [], fields(:fields_data_16).screens
  end

  def test_custom_field_ids
    assert_equal 6, fields(:fields_data_16).custom_field_id
    assert_equal ["10", "11", "12", "13"], fields(:fields_data_16).custom_field.value[:custom_field_ids]
    assert_equal [6, [10, 11, 12, 13]], fields(:fields_data_16).custom_field_ids
  end

  def test_required_search?
    assert_equal false, fields(:fields_data_50).required_search?
    assert_equal false, fields(:fields_data_16).required_search?
  end

end