require 'test_helper'

class LabelTest < ActiveSupport::TestCase
  # Replace this with your real tests.

  fixtures :labels, :captions

  def test_caption_for_all_languages
    label = labels(:labels_name)
    assert_equal Language.find(:all).length, label.captions.length
  end

  def test_captions
    label = labels(:labels_name)
    assert_equal Caption.find(:all, :conditions=>{:label_id => label.id}), label.captions
    assert_equal [], Label.new.captions
  end

  def test_custom_fields
    label = labels(:labels_name)
    assert_equal CustomField.find(:all, :conditions=>{:label_id => label.id}), label.custom_fields
    assert_equal [], Label.new.custom_fields
  end

  def test_fields
    label = labels(:labels_name)
    assert_equal Field.find(:all, :conditions=>{:label_id => label.id}), label.fields
    assert_equal [], Label.new.fields
  end

  def test_screens
    label = labels(:labels_name)
    assert_equal Screen.find(:all, :conditions=>{:label_id => label.id}), label.screens
    assert_equal [], Label.new.screens
  end

  def test_descr_by_name
    assert_equal "caption_name_en", Label.descr_by_name("labels_name")
    assert_equal "<span class='error_message'>Label with ID=nothing is missing!</span>", Label.descr_by_name("nothing")
    assert_equal "<span class='error_message'>Label with ID= is missing!</span>", Label.descr_by_name(nil)
  end

  def test_find_by_name
    assert_equal labels(:labels_name), Label.find_by_name("labels_name")
    assert_nil Label.find_by_name("nothing")
    assert_nil Label.find_by_name(nil)
  end

  def test_empty_label
    assert_equal "Text", Label.empty_label("Text").descr
    caption_texts = {
      'EN' => "EN Text",
      'TH' => "TH Text",
      'JP' => "JP Text"
    }
    label = Label.empty_label(caption_texts)
    assert_equal "EN Text", label.descr_by_lang('EN')
    assert_equal "TH Text", label.descr_by_lang('TH')
    assert_equal "JP Text", label.descr_by_lang('JP')
  end

  def test_missing_msg
    assert_equal "<span class='error_message'>Label with ID=0 is missing!</span>", Label.missing_msg(0)
    assert_equal "<span class='error_message'>Label with ID= is missing!</span>", Label.missing_msg(nil)
  end

  def test_descr
    assert_equal "caption_name_en", labels(:labels_name).descr
    assert_equal "<span class='error_message'>Caption with ID= (Language.name=EN) is missing!</span>", Label.new.descr
  end

  def test_caption
    assert_equal captions(:caption_name_en), labels(:labels_name).caption
  end

  def test_descr_by_lang
    assert_equal "caption_name_en", labels(:labels_name).descr_by_lang("EN")
  end

  def test_descr_with_name
    assert_equal "caption_name_en [labels_name]", labels(:labels_name).descr_with_name
  end
  
  def test_caption_by_lang
    assert_equal captions(:caption_name_en), labels(:labels_name).caption_by_lang("EN")
  end

  # def test_is_used?
  #    # This method just return boolean
  #    # so there are 2 test cases for checking
  #    label = Label.find( 3 )
  #    label_name = label.name
  #    assert_not_nil label_name
  #    assert_kind_of String, label_name
  #  end

end
