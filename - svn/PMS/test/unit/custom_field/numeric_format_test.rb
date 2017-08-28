require 'test_helper'

class CustomFields::NumericFormatTest < ActiveSupport::TestCase

  fixtures :custom_fields, :cells, :labels

  def test_option_collection
    assert_equal [:precision, :separator, :delimiter, :unit, :rounding, :significance, :prefix_multiplier], CustomFields::NumericFormat.option_collection
  end

  def test_rounding_collection
    assert_equal [{:name=>"ceil", :descr=>"ceil"}, {:name=>"round", :descr=>"round"}, {:name=>"None", :descr=>"None"}, {:name=>"floor", :descr=>"floor"}], CustomFields::NumericFormat.rounding_collection
  end

  def test_prefix_multiplier_collection
    assert_equal [{:descr=>"K", :name=>"K"},  {:descr=>"M", :name=>"M"},  {:descr=>"None", :name=>"None"}], CustomFields::NumericFormat.prefix_multiplier_collection
  end

  def test_find
    assert_equal nil, CustomFields::NumericFormat.find("")
    assert_equal nil, CustomFields::NumericFormat.find(nil)
  end

  def test_find_currency_unit
    assert_equal({:descr=>"($)USD - US Dollar", :name=>"USD", :symbol=>"($)"}, CustomFields::NumericFormat.find_currency_unit(:USD))
    assert_equal nil, CustomFields::NumericFormat.find_currency_unit("")
    assert_equal nil, CustomFields::NumericFormat.find_currency_unit(nil)
  end

end
