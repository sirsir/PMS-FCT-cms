require 'test_helper'

class ListScreenTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
  
  def test_prefix
    list_screen = ListScreen.find(:first) # Detail screen
    assert_equal "List", list_screen.prefix
  end
end
