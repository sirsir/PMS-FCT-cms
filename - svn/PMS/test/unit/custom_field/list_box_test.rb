require 'test_helper'

class CustomFields::ListBoxTest < ActiveSupport::TestCase

  fixtures :custom_fields, :labels, :cells

  def test_cell_label_ids
    cell_value = ["-1", "1", "2", "3"]

    assert_equal [1, 2, 3], CustomFields::ListBox.cell_label_ids(cell_value)
    assert_equal [], CustomFields::ListBox.cell_label_ids([])
    assert_equal [], CustomFields::ListBox.cell_label_ids(nil)
  end

  def test_label_ids
    assert_equal [675, 677, 676], custom_fields(:custom_fields_list_box_33).label_ids
  end

  def test_labels
    assert_equal [labels(:label_675),labels(:label_677),labels(:label_676)], custom_fields(:custom_fields_list_box_33).labels
  end

  def test_default_value
    assert_equal 675, custom_fields(:custom_fields_list_box_33).default_value
  end
  
  def test_text
    assert_equal "Bangkok", custom_fields(:custom_fields_list_box_33).text(cells(:cell_363).value)
    assert_equal "Bangkok", custom_fields(:custom_fields_list_box_33).text("675")
  end
  
  def test_html
    assert_equal "Bangkok", custom_fields(:custom_fields_list_box_33).text(cells(:cell_363).value)
  end
  
end
