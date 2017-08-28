require 'test_helper'

class DetailScreenTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
  
  def test_has_header?
    detail_screen = DetailScreen.find(:first) # Detail screen
    assert_not_nil detail_screen.header
    assert_kind_of HeaderScreen, detail_screen.header
    assert detail_screen.hasHeader?
  end

  def test_prefix
    detail_screen = DetailScreen.find(:first) # Detail screen
    assert_equal "Detail", detail_screen.prefix
  end
  
  
end
