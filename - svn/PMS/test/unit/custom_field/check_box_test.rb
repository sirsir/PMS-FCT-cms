require 'test_helper'

class CustomFields::CheckBoxTest < ActiveSupport::TestCase
  fixtures :custom_fields, :labels, :cells

  def test_cell_label_ids
    cell_value = {
      "-1" => "false",
      "1" => "true",
      "2" => "false",
      "3" => "true"
    }
    assert_equal({ 1 => true, 2 => false, 3 => true }, CustomFields::CheckBox.cell_label_ids(cell_value))
    assert_equal({}, CustomFields::CheckBox.cell_label_ids({}))
    assert_equal({}, CustomFields::CheckBox.cell_label_ids(nil))
  end
  
  def test_cell_check
    cell_value = {
      "-1" => "false",
      "1" => "true",
      "2" => "false",
      "3" => "true"
    }
    assert_equal true, CustomFields::CheckBox.cell_checked(cell_value, 1) 
    assert_equal false, CustomFields::CheckBox.cell_checked(cell_value, 2) 
    
    cell_value = {
      "-1" => "false",
      "0" => "true"
    }
    assert_equal true, CustomFields::CheckBox.cell_checked(cell_value)
    
    assert_equal false, CustomFields::CheckBox.cell_checked({}) 
    assert_equal false, CustomFields::CheckBox.cell_checked(nil)
  end
  
  def test_true_or_false?
    assert_equal false, CustomFields::CheckBox.true_or_false?(nil)
    assert_equal false, CustomFields::CheckBox.true_or_false?(false)
    assert_equal true, CustomFields::CheckBox.true_or_false?(true)
    assert_equal false, CustomFields::CheckBox.true_or_false?("false")
    assert_equal true, CustomFields::CheckBox.true_or_false?("true")
    assert_equal false, CustomFields::CheckBox.true_or_false?(0)
    assert_equal true, CustomFields::CheckBox.true_or_false?(1)
    assert_equal true, CustomFields::CheckBox.true_or_false?(-1)
  end

  def test_empty_label
    assert_equal "Check is Input Name, Unchecked is List", CustomFields::CheckBox.empty_label(labels(:label_3), labels(:label_30)).descr
  end

  def test_check_box_cell_value
    single_check_box = custom_fields(:custom_fields_check_box_16)
    assert_equal({ "-1" => false, "0" => true}, CustomFields::CheckBox.check_box_cell_value(single_check_box, true))
    assert_equal({ "-1" => false, "0" => false}, CustomFields::CheckBox.check_box_cell_value(single_check_box, false))
    multi_check_box = custom_fields(:custom_fields_check_box_18)
    assert_equal({ "-1" => false, "592" => true}, CustomFields::CheckBox.check_box_cell_value(multi_check_box, multi_check_box.default_value))
  end

  #  def test_search_value?
  #
  #  end

  def test_description
    assert_equal "Choose multiple values using checkbox", custom_fields(:custom_fields_check_box_16).description
  end

  #  def test_absolute_value
  #
  #  end

  def test_text
    cell = cells(:cell_1242)
    multi_check_box = custom_fields(:custom_fields_check_box_19)
    assert_equal "Master 1, Master 2, Master 3", multi_check_box.text(cell.value)
    assert_equal "", multi_check_box.text(nil)
    single_check_box = custom_fields(:custom_fields_check_box_17)
    cell = cells(:cell_1240)
    assert_equal "Detail Screen 1", single_check_box.text(cell.value)
    assert_equal "Detail Screen 2", single_check_box.text(nil)
  end

  def test_html
    cell = cells(:cell_1242)
    multi_check_box = custom_fields(:custom_fields_check_box_19)
    assert_equal """<li class='check_box_true'><span>Master 1</span></li><li class='check_box_true'><span>Master 2</span></li><li class='check_box_true'><span>Master 3</span></li>""",multi_check_box.html(cell.value)
    assert_equal "", multi_check_box.html(nil)
    single_check_box = custom_fields(:custom_fields_check_box_17)
    cell = cells(:cell_1240)
    assert_equal "Detail Screen 1",single_check_box.html(cell.value)
  end

  def test_label_ids
    multi_check_box = custom_fields(:custom_fields_check_box_19)
    assert_equal [602, 603, 604], multi_check_box.label_ids
    single_check_box = custom_fields(:custom_fields_check_box_17)
    assert_equal [], single_check_box.label_ids
  end

  def test_labels
    multi_check_box = custom_fields(:custom_fields_check_box_19)
    assert_equal [labels(:label_602),labels(:label_603),labels(:label_604)], multi_check_box.labels
    single_check_box = custom_fields(:custom_fields_check_box_17)
    assert_equal [], single_check_box.labels
  end
  
  def test_new_line?
    assert_equal false, custom_fields(:custom_fields_check_box_19).new_line?
  end

  def test_is_empty?
    cell = cells(:cell_1240)
    single_check_box = custom_fields(:custom_fields_check_box_17)
    assert_equal false, single_check_box.is_empty?(cell.value)
    cell = cells(:cell_1242)
    multi_check_box = custom_fields(:custom_fields_check_box_19)
    assert_equal false, multi_check_box.is_empty?(cell.value)
  end

  def test_default_value
    assert_equal ["checked"], custom_fields(:custom_fields_check_box_16).default_value
    assert_equal ["unchecked"], custom_fields(:custom_fields_check_box_17).default_value
    assert_equal ["592"], custom_fields(:custom_fields_check_box_18).default_value
    assert_equal [], custom_fields(:custom_fields_check_box_19).default_value 
  end

  def test_evaluate_default_value
    assert_equal({"0"=>true}, custom_fields(:custom_fields_check_box_16).evaluate_default_value)
    assert_equal({"0"=>false}, custom_fields(:custom_fields_check_box_17).evaluate_default_value)
    assert_equal({"592"=>false, "593"=>false, "594"=>false}, custom_fields(:custom_fields_check_box_18).evaluate_default_value)
    assert_equal({"602"=>false, "603"=>false, "604"=>false}, custom_fields(:custom_fields_check_box_19).evaluate_default_value)
  end

  def test_true_label_id
    single_check_box = custom_fields(:custom_fields_check_box_17)
    assert_equal "609", single_check_box.true_label_id
  end

  def test_true_label
    singel_check_box = custom_fields(:custom_fields_check_box_17)
    assert_equal labels(:label_609), singel_check_box.true_label
  end

  def test_false_label_id
    single_check_box = custom_fields(:custom_fields_check_box_17)
    assert_equal "610", single_check_box.false_label_id
  end

  def test_false_label
    single_check_box = custom_fields(:custom_fields_check_box_17)
    assert_equal labels(:label_610), single_check_box.false_label
  end

  def test_single_value?
    single_check_box = custom_fields(:custom_fields_check_box_17)
    assert_equal true, single_check_box.single_value?
    multi_check_box = custom_fields(:custom_fields_check_box_19)
    assert_equal false, multi_check_box.single_value?
  end

  def test_multi_value?
    single_check_box = custom_fields(:custom_fields_check_box_17)
    assert_equal false, single_check_box.multi_value?
    multi_check_box = custom_fields(:custom_fields_check_box_19)
    assert_equal true, multi_check_box.multi_value?
  end

  def test_checked_value?
    single_check_box = custom_fields(:custom_fields_check_box_17)
    assert_equal false, single_check_box.checked_value?
  end

  def test_unchecked_value?
    single_check_box = custom_fields(:custom_fields_check_box_17)
    assert_equal true, single_check_box.unchecked_value?
  end

  def test_check_box_type?
    single_check_box = custom_fields(:custom_fields_check_box_17)
    assert_equal "single", single_check_box.check_box_type?
    multi_check_box = custom_fields(:custom_fields_check_box_19)
    assert_equal "multi", multi_check_box.check_box_type?
  end
end 
