require 'test_helper'

class LanguageTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_is_used?
    # This method just return boolean
    # so there are 2 test cases for checking
    language = Language.find( 1 ) 
    language_name = language.name
    assert_not_nil language_name
    assert_kind_of String, language_name
  end
end
