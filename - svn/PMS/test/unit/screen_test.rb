
require 'test_helper'

class ScreenTest < ActiveSupport::TestCase

  fixtures :screens, :fields, :custom_fields

  #  # Replace this with your real tests.
  #  def test_is_used?
  #    # This method just return boolean
  #    screen = Screen.find( 71 )
  #    screen_name = screen.name
  #    screen_type = screen.type
  #
  #    assert_not_nil screen_name
  #    assert_not_nil screen_type
  #    assert_kind_of String, screen_name
  #    assert_equal "HeaderScreen" , screen_type
  #  end
  #
  #  def test_length_header_detail?
  #    # test type Header and detail [header(1) <=> detail(1)]
  #    header_screen = Screen.find( 71 ) # quatation
  #    detail_screen = Screen.find(:all ,:conditions => ["screen_id = ?", header_screen.id ]) # quatation_detail
  #    assert_equal 1 , detail_screen.length
  #
  #    # test type Header and detail [header(1) <=> detail(2)]
  #    header_screen = Screen.find( 82 ) # Person in charge
  #    detail_screen = Screen.find(:all ,:conditions => ["screen_id = ?", header_screen.id ]) # quatation_detail
  #    assert_equal 2 , detail_screen.length
  #  end

  def test_missing_msg
    assert_equal "<span class='error_message'>Screen with ID=0 is missing!</span>", Screen.missing_msg(0)
    assert_equal "<span class='error_message'>Screen with ID= is missing!</span>", Screen.missing_msg("")
    assert_equal "<span class='error_message'>Screen with ID= is missing!</span>", Screen.missing_msg(nil)
  end

  def test_transaction_childs
    assert_equal [], screens(:header_screen_204).transaction_childs
    assert_equal [], screens(:list_screen_211).transaction_childs
  end

  def test_field
    assert_equal fields(:fields_data_16), screens(:list_screen_186).field(16)
  end

  def test_label_descr
    assert_equal "Test Auto Numbering", screens(:list_screen_186).label_descr
  end

  def test_label_descr_with_name
    assert_equal "Test Auto Numbering [Test Auto Numbering]", screens(:list_screen_186).label_descr_with_name
  end

  def test_system?
    assert_equal false, screens(:list_screen_186).system?
    assert_equal true, screens(:menu_group_screen_1).system?
  end

  def test_control_revision?
    assert_equal false, screens(:menu_group_screen_187).system?
  end
  
  def test_level
    assert_equal 2, screens(:menu_group_screen_1).level
    assert_equal 8, screens(:menu_group_screen_1).screen_id
    assert_equal 1, screens(:menu_group_screen_8).level
    assert_nil screens(:menu_group_screen_8).screen_id
    assert_equal 3, screens(:menu_group_screen_187).level
  end

  def test_field_level
    assert_equal 1, screens(:menu_group_screen_1).field_level
    assert_equal 1, screens(:list_screen_11).field_level
    assert_equal 1, screens(:screen_21).field_level
    assert_equal 1, screens(:header_screen_147).field_level
    assert_equal 1, screens(:detail_screen_196).field_level
  end

  def test_list_fields_level
    assert_equal [], screens(:menu_group_screen_1).list_fields_level(1)
    assert_equal [], screens(:list_screen_11).list_fields_level(1)
    assert_equal [], screens(:screen_21).list_fields_level(1)
    assert_equal [], screens(:header_screen_147).list_fields_level(1)
    #    assert_equal [], screens(:detail_screen_196).list_fields_level(1)
  end

  def test_non_ref_description_custom_field_ids
    assert_equal [], screens(:menu_group_screen_1).non_ref_description_custom_field_ids
    assert_equal [], screens(:list_screen_11).non_ref_description_custom_field_ids
    assert_equal [], screens(:screen_21).non_ref_description_custom_field_ids
    assert_equal [], screens(:header_screen_147).non_ref_description_custom_field_ids
    assert_equal [], screens(:detail_screen_196).non_ref_description_custom_field_ids
  end

  def test_default_sort_field_id_order
    assert_equal [], screens(:menu_group_screen_1).default_sort_field_id_order
    assert_equal [], screens(:list_screen_11).default_sort_field_id_order
    assert_equal [], screens(:screen_21).default_sort_field_id_order
    assert_equal [], screens(:header_screen_147).default_sort_field_id_order
    assert_equal [50, 119, 129], screens(:detail_screen_196).default_sort_field_id_order
  end

  def test_path_ids
    assert_equal [1], screens(:menu_group_screen_1).path_ids
    assert_equal [11, 1], screens(:list_screen_11).path_ids
    assert_equal [21, 6], screens(:screen_21).path_ids
    assert_equal [147, 1], screens(:header_screen_147).path_ids
    assert_equal [196, 37], screens(:detail_screen_196).path_ids
  end

  def test_display_in_menu?
    assert_equal true, screens(:menu_group_screen_1).display_in_menu?
    assert_equal true, screens(:list_screen_11).display_in_menu?
    assert_equal true, screens(:screen_21).display_in_menu?
    assert_equal true, screens(:header_screen_147).display_in_menu?
    assert_equal false, screens(:detail_screen_196).display_in_menu?
  end

  def test_has_child_display_in_menu?
    #    assert_equal false, screens(:menu_group_screen_1).has_child_display_in_menu?
    assert_equal true, screens(:list_screen_11).has_child_display_in_menu?
    assert_equal true, screens(:screen_21).has_child_display_in_menu?
    assert_equal true, screens(:header_screen_147).has_child_display_in_menu?
    assert_equal true, screens(:detail_screen_196).has_child_display_in_menu?
  end

  def test_display_as_menu_item?
    assert_equal false, screens(:menu_group_screen_1).display_as_menu_item?
    assert_equal true, screens(:list_screen_11).display_as_menu_item?
    assert_equal true, screens(:screen_21).display_as_menu_item?
    assert_equal true, screens(:header_screen_147).display_as_menu_item?
    assert_equal false, screens(:detail_screen_196).display_as_menu_item?
  end

  def test_prefix
    assert_equal "MenuGroup", screens(:menu_group_screen_1).prefix
    assert_equal "List", screens(:list_screen_11).prefix
    assert_equal "", screens(:screen_21).prefix
    assert_equal "Header", screens(:header_screen_147).prefix
    assert_equal "Detail", screens(:detail_screen_196).prefix
  end

  def test_relations
    #    assert_equal [], screens(:menu_group_screen_1).relations
    assert_equal [], screens(:list_screen_11).relations
    assert_equal [], screens(:screen_21).relations
    assert_equal [], screens(:header_screen_147).relations
    assert_equal [], screens(:detail_screen_196).relations
  end

  def test_relation_types
    relate_screens = screens(:menu_group_screen_1).relations
    assert_equal [], screens(:menu_group_screen_1).relation_types(relate_screens[0])
    assert_equal [], screens(:menu_group_screen_1).relation_types(relate_screens[1])
    assert_equal [], screens(:menu_group_screen_1).relation_types(relate_screens[2])
    assert_equal [], screens(:menu_group_screen_1).relation_types(relate_screens[3])
    assert_equal [], screens(:menu_group_screen_1).relation_types(relate_screens[4])
    assert_equal [], screens(:menu_group_screen_1).relation_types(relate_screens[5])
    assert_equal [], screens(:menu_group_screen_1).relation_types(relate_screens[6])
    assert_equal [], screens(:menu_group_screen_1).relation_types(relate_screens[7])
  end

  def test_used?
    assert_equal false, screens(:menu_group_screen_1).used?
    assert_equal false, screens(:list_screen_11).used?
    assert_equal false, screens(:screen_21).used?
    assert_equal false, screens(:header_screen_147).used?
    assert_equal false, screens(:detail_screen_196).used?
  end

  def test_reference_custom_fields
    assert_equal [], screens(:menu_group_screen_1).reference_custom_fields
    assert_equal [], screens(:list_screen_11).reference_custom_fields
    assert_equal [], screens(:screen_21).reference_custom_fields
    assert_equal [], screens(:header_screen_147).reference_custom_fields
    assert_equal [], screens(:detail_screen_196).reference_custom_fields
  end

  def test_reference_custom_field_ids
    assert_equal [], screens(:menu_group_screen_1).reference_custom_field_ids
    assert_equal [], screens(:list_screen_11).reference_custom_field_ids
    assert_equal [], screens(:screen_21).reference_custom_field_ids
    assert_equal [], screens(:header_screen_147).reference_custom_field_ids
    assert_equal [], screens(:detail_screen_196).reference_custom_field_ids
  end

  def test_reference_custom_field_ids
    assert_equal [], screens(:menu_group_screen_1).reference_custom_field_ids
    assert_equal [], screens(:list_screen_11).reference_custom_field_ids
    assert_equal [], screens(:screen_21).reference_custom_field_ids
    assert_equal [], screens(:header_screen_147).reference_custom_field_ids
    assert_equal [], screens(:detail_screen_196).reference_custom_field_ids
  end

  def test_has_a?
    assert_equal true, screens(:detail_screen_196).has_a?(CustomFields::TextField)
    assert_equal false, screens(:detail_screen_196).has_a?(CustomFields::Calendar)
  end

  def test_has_scr_field?
    assert_equal false, screens(:menu_group_screen_1).has_scr_field?
    assert_equal false, screens(:list_screen_11).has_scr_field?
    assert_equal false, screens(:screen_21).has_scr_field?
    assert_equal false, screens(:header_screen_147).has_scr_field?
    assert_equal false, screens(:detail_screen_196).has_scr_field?
  end

  def test_has_a_auto_numbering_with_unique?
    assert_equal false, screens(:menu_group_screen_1).has_a_auto_numbering_with_unique?
    assert_equal false, screens(:list_screen_11).has_a_auto_numbering_with_unique?
    assert_equal false, screens(:screen_21).has_a_auto_numbering_with_unique?
    assert_equal false, screens(:header_screen_147).has_a_auto_numbering_with_unique?
    assert_equal false, screens(:detail_screen_196).has_a_auto_numbering_with_unique?
  end

  def test_l2r_custom_fields
    assert_equal [], screens(:menu_group_screen_1).l2r_custom_fields
    assert_equal [], screens(:list_screen_11).l2r_custom_fields
    assert_equal [], screens(:screen_21).l2r_custom_fields
    assert_equal [], screens(:header_screen_147).l2r_custom_fields
    assert_equal [], screens(:detail_screen_196).l2r_custom_fields
  end

  def test_scr_custom_fields
    assert_equal [], screens(:menu_group_screen_1).scr_custom_fields
    assert_equal [], screens(:list_screen_11).scr_custom_fields
    assert_equal [], screens(:screen_21).scr_custom_fields
    assert_equal [], screens(:header_screen_147).scr_custom_fields
    assert_equal [], screens(:detail_screen_196).scr_custom_fields
  end

  def test_dependencies
    #    assert_equal [], screens(:menu_group_screen_1).dependencies
    assert_equal [], screens(:list_screen_11).dependencies
    assert_equal [], screens(:screen_21).dependencies
    assert_equal [], screens(:header_screen_147).dependencies
    assert_equal [], screens(:detail_screen_196).dependencies
  end

  def test_dependents
    assert_equal [], screens(:menu_group_screen_1).dependents
    assert_equal [], screens(:list_screen_11).dependents
    assert_equal [], screens(:screen_21).dependents
    assert_equal [], screens(:header_screen_147).dependents
    assert_equal [], screens(:detail_screen_196).dependents
  end
  
  def test_menu_group_screen?
    assert_equal true, screens(:menu_group_screen_1).menu_group_screen?
    assert_equal false, screens(:list_screen_11).menu_group_screen?
    assert_equal false, screens(:screen_21).menu_group_screen?
    assert_equal false, screens(:header_screen_147).menu_group_screen?
    assert_equal false, screens(:detail_screen_196).menu_group_screen?
  end
  
  def test_login_reference_custom_field_ids
    assert_equal [], screens(:menu_group_screen_1).login_reference_custom_field_ids
    assert_equal [], screens(:list_screen_11).login_reference_custom_field_ids
    assert_equal [], screens(:screen_21).login_reference_custom_field_ids
    assert_equal [], screens(:header_screen_147).login_reference_custom_field_ids
    assert_equal [], screens(:detail_screen_196).login_reference_custom_field_ids    
  end

  def test_has_login_custom_field?
    assert_equal false, screens(:menu_group_screen_1).has_login_custom_field?
    assert_equal false, screens(:list_screen_11).has_login_custom_field?
    assert_equal false, screens(:screen_21).has_login_custom_field?
    assert_equal false, screens(:header_screen_147).has_login_custom_field?
    assert_equal false, screens(:detail_screen_196).has_login_custom_field?
  end

  def test_unuse_user
    assert_equal ["admin_user", "delete_user", "edit_user", "new_user", "view_user"], screens(:menu_group_screen_1).unuse_user
    assert_equal ["admin_user", "delete_user", "edit_user", "new_user", "view_user"], screens(:list_screen_11).unuse_user
    assert_equal ["admin_user", "delete_user", "edit_user", "new_user", "view_user"], screens(:screen_21).unuse_user
    assert_equal ["admin_user", "delete_user", "edit_user", "new_user", "view_user"], screens(:header_screen_147).unuse_user
    assert_equal ["admin_user", "delete_user", "edit_user", "new_user", "view_user"], screens(:detail_screen_196).unuse_user
  end

  def test_has_loginfield?
    assert_equal false, screens(:menu_group_screen_1).has_loginfield?
    assert_equal false, screens(:list_screen_11).has_loginfield?
    assert_equal false, screens(:screen_21).has_loginfield?
    assert_equal false, screens(:header_screen_147).has_loginfield?
    assert_equal false, screens(:detail_screen_196).has_loginfield?
  end
  
  def test_get_staff_ref_field_id
    assert_equal nil, screens(:menu_group_screen_1).get_staff_ref_field_id
    assert_equal nil, screens(:list_screen_11).get_staff_ref_field_id
    assert_equal nil, screens(:screen_21).get_staff_ref_field_id
    assert_equal nil, screens(:header_screen_147).get_staff_ref_field_id
    assert_equal nil, screens(:detail_screen_196).get_staff_ref_field_id
  end

  def test_has_issue_tracking_field
    assert_equal false, screens(:menu_group_screen_1).has_issue_tracking_field
    assert_equal false, screens(:list_screen_11).has_issue_tracking_field
    assert_equal false, screens(:screen_21).has_issue_tracking_field
    assert_equal false, screens(:header_screen_147).has_issue_tracking_field
    assert_equal false, screens(:detail_screen_196).has_issue_tracking_field
  end

  def test_get_releted_screens_for_special_search
    assert_equal [], screens(:menu_group_screen_1).get_releted_screens_for_special_search
    assert_equal [], screens(:list_screen_11).get_releted_screens_for_special_search
    assert_equal [], screens(:screen_21).get_releted_screens_for_special_search
    assert_equal [], screens(:header_screen_147).get_releted_screens_for_special_search
    assert_equal [], screens(:detail_screen_196).get_releted_screens_for_special_search
  end

  def test_get_parent_screen
    assert_equal screens(:menu_group_screen_8), screens(:menu_group_screen_1).get_parent_screen
    assert_equal screens(:menu_group_screen_1), screens(:list_screen_11).get_parent_screen
    assert_equal screens(:menu_group_screen_6), screens(:screen_21).get_parent_screen
    assert_equal screens(:menu_group_screen_1), screens(:header_screen_147).get_parent_screen
    assert_equal screens(:menu_group_screen_37), screens(:detail_screen_196).get_parent_screen
  end

  def test_get_alias_screen
    assert_equal nil, screens(:menu_group_screen_1).get_alias_screen.id
    assert_equal nil, screens(:list_screen_11).get_alias_screen.id
    assert_equal nil, screens(:screen_21).get_alias_screen.id
    assert_equal nil, screens(:header_screen_147).get_alias_screen.id
    assert_equal nil, screens(:detail_screen_196).get_alias_screen.id
  end

  def test_get_relate_screen
    assert_equal nil, screens(:menu_group_screen_1).get_relate_screen.id
    assert_equal nil, screens(:list_screen_11).get_relate_screen.id
    assert_equal nil, screens(:screen_21).get_relate_screen.id
    assert_equal nil, screens(:header_screen_147).get_relate_screen.id
    assert_equal nil, screens(:detail_screen_196).get_relate_screen.id
  end

  def test_get_relate_screen
    assert_equal "-", screens(:menu_group_screen_1).get_alias_screen_name
    assert_equal "-", screens(:list_screen_11).get_alias_screen_name
    assert_equal "-", screens(:screen_21).get_alias_screen_name
    assert_equal "-", screens(:header_screen_147).get_alias_screen_name
    assert_equal "-", screens(:detail_screen_196).get_alias_screen_name
  end

  def test_get_relate_screen_name
    assert_equal "-", screens(:menu_group_screen_1).get_relate_screen_name
    assert_equal "-", screens(:list_screen_11).get_relate_screen_name
    assert_equal "-", screens(:screen_21).get_relate_screen_name
    assert_equal "-", screens(:header_screen_147).get_relate_screen_name
    assert_equal "-", screens(:detail_screen_196).get_relate_screen_name
  end
  
  def test_has_field?
    screen = screens(:detail_screen_196)
    assert_equal true, screen.has_field?(CustomFields::TextField)
    assert_equal false, screen.has_field?(CustomFields::Calendar)
  end

  def test_accumulate_fields
    assert_equal 0, screens(:menu_group_screen_1).accumulate_fields.length
    assert_equal 0, screens(:list_screen_11).accumulate_fields.length
    assert_equal 0, screens(:screen_21).accumulate_fields.length
    assert_equal 0, screens(:header_screen_147).accumulate_fields.length
    assert_equal 3, screens(:detail_screen_196).accumulate_fields.length
  end

  def test_date_fields
    assert_equal 0, screens(:menu_group_screen_1).date_fields.length
    assert_equal 0, screens(:list_screen_11).date_fields.length
    assert_equal 0, screens(:screen_21).date_fields.length
    assert_equal 0, screens(:header_screen_147).date_fields.length
    assert_equal 0, screens(:detail_screen_196).date_fields.length
  end

  def test_comparable_fields
    assert_equal 0, screens(:menu_group_screen_1).comparable_fields.length
    assert_equal 0, screens(:list_screen_11).comparable_fields.length
    assert_equal 0, screens(:screen_21).comparable_fields.length
    assert_equal 0, screens(:header_screen_147).comparable_fields.length
    assert_equal 2, screens(:detail_screen_196).comparable_fields.length
  end

  def test_references_custom_fields
    assert_equal 0, screens(:menu_group_screen_1).references_custom_fields.length
    assert_equal 0, screens(:list_screen_11).references_custom_fields.length
    assert_equal 0, screens(:screen_21).references_custom_fields.length
    assert_equal 0, screens(:header_screen_147).references_custom_fields.length
    assert_equal 0, screens(:detail_screen_196).references_custom_fields.length
  end

  def test_has_required_search?
    assert_equal false, screens(:menu_group_screen_1).has_required_search?
    assert_equal false, screens(:list_screen_11).has_required_search?
    assert_equal false, screens(:screen_21).has_required_search?
    assert_equal false, screens(:header_screen_147).has_required_search?
    assert_equal false, screens(:detail_screen_196).has_required_search?
  end

  def test_include_required_search?
#    screen = screens(:detail_screen_196)
#    custom_fields = [custom_fields(:custom_fields_text_field_1), custom_fields(:custom_fields_text_field_2)]
#    assert_equal true, screen.include_required_search?(custom_fields)
#    assert_equal true, screen.include_required_search?([])
#    assert_equal true, screen.include_required_search?(nil)
  end

  def test_has_field
    screen = screens(:detail_screen_196)
    assert_equal 0, screen.has_field(0).length
    assert_equal 50, screen.has_field(1).first.id
    assert_equal 0, screen.has_field(2).length
    assert_equal 0, screen.has_field(nil).length
  end

  def test_filter_custom_fields
    screen = screens(:detail_screen_196)
    custom_fields = [custom_fields(:custom_fields_text_field_1), custom_fields(:custom_fields_text_field_2)]
    assert_equal [custom_fields(:custom_fields_text_field_1)], screen.filter_custom_fields(custom_fields)
    assert_equal [], screen.filter_custom_fields([])
  end

  def test_screen_combined_reference_field
    assert_equal nil, screens(:menu_group_screen_1).screen_combined_reference_field()
    assert_equal nil, screens(:list_screen_11).screen_combined_reference_field()
    assert_equal nil, screens(:screen_21).screen_combined_reference_field()
    assert_equal nil, screens(:header_screen_147).screen_combined_reference_field()
    assert_equal nil, screens(:detail_screen_196).screen_combined_reference_field()
  end

  def test_option_combined_reference_field
    assert_equal nil, screens(:menu_group_screen_1).option_combined_reference_field()
    assert_equal nil, screens(:list_screen_11).option_combined_reference_field()
    assert_equal nil, screens(:screen_21).option_combined_reference_field()
    assert_equal nil, screens(:header_screen_147).option_combined_reference_field()
    assert_equal nil, screens(:detail_screen_196).option_combined_reference_field()
  end

  def test_header_fields
    assert_equal [], screens(:menu_group_screen_1).header_fields
    assert_equal [], screens(:list_screen_11).header_fields
    assert_equal [], screens(:screen_21).header_fields
    assert_equal [], screens(:header_screen_147).header_fields
    assert_equal [], screens(:detail_screen_196).header_fields
  end

  def test_reference_attribute_fields
    assert_equal [], screens(:menu_group_screen_1).reference_attribute_fields
    assert_equal [], screens(:list_screen_11).reference_attribute_fields
    assert_equal [], screens(:screen_21).reference_attribute_fields
    assert_equal [], screens(:header_screen_147).reference_attribute_fields
    assert_equal [], screens(:detail_screen_196).reference_attribute_fields
  end

  def test_find_descr_field
    assert_equal nil, screens(:menu_group_screen_1).find_descr_field
    assert_equal nil, screens(:list_screen_11).find_descr_field
    assert_equal nil, screens(:screen_21).find_descr_field
    assert_equal nil, screens(:header_screen_147).find_descr_field
    assert_equal fields(:fields_data_129), screens(:detail_screen_196).find_descr_field
  end

  def test_require_permission?
    assert_equal true, screens(:menu_group_screen_1).require_permission?
    assert_equal true, screens(:list_screen_11).require_permission?
    assert_equal true, screens(:screen_21).require_permission?
    assert_equal true, screens(:header_screen_147).require_permission?
    assert_equal true, screens(:detail_screen_196).require_permission?
  end
end