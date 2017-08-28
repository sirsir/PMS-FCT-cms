require 'test_helper'

class CustomFields::RadioButtonTest < ActiveSupport::TestCase

  fixtures :custom_fields, :labels

  def test_cell_label_id
    assert_equal 1, CustomFields::RadioButton.cell_label_id({:label => "1"})
    assert_equal 0, CustomFields::RadioButton.cell_label_id({})
    assert_equal 0, CustomFields::RadioButton.cell_label_id(nil)
  end

  def test_cell_label_ids
    assert_equal 1, CustomFields::RadioButton.cell_label_id({:label => "1"})
    assert_equal 0, CustomFields::RadioButton.cell_label_id({})
    assert_equal 0, CustomFields::RadioButton.cell_label_id(nil)
  end

  def test_absolute_value
    assert_equal labels(:label_620), custom_fields(:custom_fields_radio_button_53).absolute_value({:label => "620"})
    assert_nil custom_fields(:custom_fields_radio_button_53).absolute_value({})
    assert_nil custom_fields(:custom_fields_radio_button_53).absolute_value(nil)
  end

  def test_text
    assert_equal "Numeric 1", custom_fields(:custom_fields_radio_button_53).text({:label => "620"})
    assert_equal "", custom_fields(:custom_fields_radio_button_53).text({})
    assert_equal "", custom_fields(:custom_fields_radio_button_53).text(nil)
  end

  def test_html
    assert_equal "Numeric 1", custom_fields(:custom_fields_radio_button_53).html({:label => "620"})
    assert_equal "<span class='error_message'>Label with ID=0 is missing!</span>", custom_fields(:custom_fields_radio_button_53).html({})
    assert_equal "<span class='error_message'>Label with ID=0 is missing!</span>", custom_fields(:custom_fields_radio_button_53).html(nil)
  end

  def test_label_ids
    assert_equal [620, 621], custom_fields(:custom_fields_radio_button_53).label_ids
  end

  def test_labels
    assert_equal [labels(:label_620), labels(:label_621)], custom_fields(:custom_fields_radio_button_53).labels
  end

  def test_new_line?
    assert_equal false, custom_fields(:custom_fields_radio_button_53).new_line?
  end

  def test_defaul_value
    assert_equal 620, custom_fields(:custom_fields_radio_button_53).default_value
  end

  def test_evaluate_default_value
    assert_equal({:label=>620}, custom_fields(:custom_fields_radio_button_53).evaluate_default_value)
  end

end