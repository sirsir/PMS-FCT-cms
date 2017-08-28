require 'test_helper'

class CustomFields::ReferenceTest < ActiveSupport::TestCase

  fixtures :custom_fields, :cells, :rows

  def test_field_related_to
   assert_equal 1, CustomFields::Reference.field_related_to({:relate_to => 1})
   assert_equal 0, CustomFields::Reference.field_related_to({})
   assert_equal 0, CustomFields::Reference.field_related_to(nil)
  end

  def test_field_related_from
    assert_equal 1, CustomFields::Reference.field_related_from({:related_from => 1})
    assert_equal 0, CustomFields::Reference.field_related_from({})
    assert_equal 0, CustomFields::Reference.field_related_from(nil)
  end

  def test_cell_ref_row_id
    assert_equal 1, CustomFields::Reference.cell_ref_row_id({:row_id => "1"})
    assert_equal 0, CustomFields::Reference.cell_ref_row_id({})
    assert_equal 0, CustomFields::Reference.cell_ref_row_id(nil)
  end

  def test_find_all
    assert_equal CustomField.find(:all, :conditions => {:type => "CustomFields::Reference"}), CustomFields::Reference.find_all
  end

  def test_screen_id
    assert_equal 189, custom_fields(:custom_fields_reference_10).screen_id
  end

  def test_screen
    assert_equal screens(:list_screen_189), custom_fields(:custom_fields_reference_10).screen
  end

  def test_custom_field_ids
    assert_equal [], custom_fields(:custom_fields_reference_10).custom_field_ids
  end

  def test_custom_fields
    assert_equal [], custom_fields(:custom_fields_reference_10).custom_fields
  end

  def test_control_type
    assert_equal "combo_box", custom_fields(:custom_fields_reference_10).control_type
  end

  def test_descr_separator
    assert_equal " - ", custom_fields(:custom_fields_reference_10).descr_separator
  end

  def test_searchable_text?
    assert_nil custom_fields(:custom_fields_reference_10).searchable_text?
  end

  def test_absolute_value
    assert_equal({"row"=>   rows(:list_row_1)}, custom_fields(:custom_fields_reference_10).absolute_value(cells(:cell_589).value))
  end
end