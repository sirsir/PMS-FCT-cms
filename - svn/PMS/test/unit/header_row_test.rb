require 'test_helper'

class HeaderRowTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
    
  def test_has_details?
    header_row = HeaderRow.find(:first) # Header row
    assert header_row.details.length >= 1
    
    header_row.details.each do |screen_detail|
      assert_kind_of DetailScreen, screen_detail
    end  
    
  end  
  
  def test_rows
    detail_screen = DetailScreen.find(76) # Detail screen
    detail_screen.header.filter_row_id  = 1
    assert detail_screen.rows.length == 1
    
    DetailScreen.header.filter_row_id  = 2
    assert detail_screen.rows.length == 1
    
    
    detail_screen = DetailScreen.find(69) # Detail screen
    detail_screen.header.filter_row_id  = 1
    assert detail_screen.rows.length == 3
    
    detail_screen.header.filter_row_id  = 2
    assert detail_screen.rows.length == 1
  end
end
