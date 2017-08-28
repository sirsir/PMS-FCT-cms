require 'test_helper'

class CustomFields::LeftRightTest < ActiveSupport::TestCase

  fixtures :cells, :custom_fields, :rows, :screens

  def test_field_related_to
    assert_equal 1, CustomFields::LeftRight.field_related_to({:relate_to => 1})
    assert_equal 0, CustomFields::LeftRight.field_related_to({})
    assert_equal 0, CustomFields::LeftRight.field_related_to(nil)
  end

  def test_field_related_from
    assert_equal 1, CustomFields::LeftRight.field_related_from({:related_from => 1})
    assert_equal 0, CustomFields::LeftRight.field_related_from({})
    assert_equal 0, CustomFields::LeftRight.field_related_from(nil)
  end

  def test_cell_ref_row_ids
    assert_equal [1, 2, 3], CustomFields::LeftRight.cell_ref_row_ids(["1", "2", "3"])
    assert_equal [], CustomFields::LeftRight.cell_ref_row_ids([])
    assert_equal [], CustomFields::LeftRight.cell_ref_row_ids(nil)
  end

  def test_absolute_value
    assert_equal [rows(:list_row_1), rows(:list_row_2)], custom_fields(:custom_fields_left_right_50).absolute_value(cells(:cell_353).value)
  end

  def test_screen_id
    assert_equal 189, custom_fields(:custom_fields_left_right_50).screen_id
  end

  def test_screen
    assert_equal screens(:list_screen_189), custom_fields(:custom_fields_left_right_50).screen
  end

  def test_default_value
    assert_equal ["-1"], custom_fields(:custom_fields_left_right_50).default_value
  end
end
