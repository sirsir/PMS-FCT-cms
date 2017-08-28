require 'test_helper'

class AutoNumberRunningTest < ActiveSupport::TestCase
  
  fixtures :custom_fields
  
  def test_cell_text
    assert_equal "123456",CustomFields::AutoNumbering.cell_text({ :text => "123456" })
    assert_equal "",CustomFields::AutoNumbering.cell_text({})
    assert_equal "",CustomFields::AutoNumbering.cell_text(nil)
  end

  def test_set_cell_text
    assert_equal "67890", CustomFields::AutoNumbering.set_cell_text({:text => "12345"}, "67890")
    assert_equal "12345", CustomFields::AutoNumbering.set_cell_text({}, "12345")
    assert_equal "12345", CustomFields::AutoNumbering.set_cell_text(nil, "12345")
  end

  def test_cell_date
    assert_equal "2010/01/01".to_date, CustomFields::AutoNumbering.cell_date({ :date => "2010/01/01" })
    assert_equal Date.null_date, CustomFields::AutoNumbering.cell_date({})
    assert_equal Date.null_date, CustomFields::AutoNumbering.cell_date(nil)
  end
  
  def test_format_key
    assert_equal "yymmdd-", custom_fields(:custom_fields_auto_numbering_62).format_key
  end

  def test_reference_custom_field_ids
    assert_equal [10,11,12,13], custom_fields(:custom_fields_auto_numbering_6).reference_custom_field_ids
  end

  def test_reference_custom_field
    assert_equal CustomFields::Reference.find([10,11,12,13]), custom_fields(:custom_fields_auto_numbering_6).reference_custom_fields
  end
end