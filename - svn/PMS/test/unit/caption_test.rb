require 'test_helper'

class CaptionTest < ActiveSupport::TestCase
  # Replace this with your real tests.

   fixtures :captions, :labels, :languages
#
# def test_is_used?
#    # This method just return boolean
#    # so there are 2 test cases for checking
#    caption = Caption.find( 7 )
#    caption_name = caption.name
#    assert_not_nil caption_name
#    assert_kind_of String, caption_name
#  end

  def test_label
    assert_equal labels(:labels_name), captions(:caption_name_en).label
    assert_equal labels(:labels_name), captions(:caption_name_th).label
    assert_equal labels(:labels_name), captions(:caption_name_jp).label
  end

  def test_language
    assert_equal languages(:languages_en), captions(:caption_name_en).language
    assert_equal languages(:languages_th), captions(:caption_name_th).language
    assert_equal languages(:languages_jp), captions(:caption_name_jp).language
  end

  def test_descr
    assert_equal "caption_name_en", captions(:caption_name_en).descr
  end

  def test_missing_msg
    caption_id = 999
    assert_equal "<span class='error_message'>Caption with ID=999 is missing!</span>", Caption.missing_msg(caption_id)
    assert_equal "<span class='error_message'>Caption with ID=999 (Extra info) is missing!</span>", Caption.missing_msg(caption_id, "Extra info")
  end
end