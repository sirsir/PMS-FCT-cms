require 'test_helper'

class HeaderScreenTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
  
  def test_has_details?
    header_screen = HeaderScreen.find(:first) # Header screen
    assert header_screen.details.length >= 1
    assert header_screen.hasDetail?
    
    header_screen.details.each do |detail_screen|
      assert_kind_of DetailScreen, detail_screen
      assert detail_screen.hasHeader?
    end  
    
  end  

  def test_prefix
    header_screen = HeaderScreen.find(:first) # Detail screen
    assert_equal "Header", header_screen.prefix
   
  end
 
end
