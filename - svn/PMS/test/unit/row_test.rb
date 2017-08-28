require 'test_helper'

class RowTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "details" do
    screens = Screen.find(:all)
    puts screens.to_yaml
    # row = Row.find(226)
    # screens = row.details
    # assert screens[0].name == "Quotation Details"
  end
  
  test "log" do
    row = Rows.find(227)
    asset_is_a Row::Log, row.log
    asset_is_a User, row.log.user
    asset_is_a Date, row.log.transaction_date
    asset_is_a hash, row.log.fileds
  end
  
  test "log_summary" do
    # Test new item
    row = Rows.find(226)
    assert_equal "Created by Danz on 2007/01/01", row.log_summary
    
    # Test modified-once item
    row = Rows.find(227)
    assert_equal "Created by Danz on 2007/01/01, Updated by Danz on 2007/01/01", row.log_summary
  end
  
#  test "sort" do
#    row_ids = rows.collect{|r| r.id }
#    asset_equal [1,2,3,4,5,6,7,8,9,10], row_ids
#
#    row_ids = Row.sort(row_ids)
#    asset_equal [4,2,5,3,6,1,7,8,9,10], row_ids
#
#    row_ids = Row.sort(row_ids)
#    asset_equal [9,7,5,3,1,2,4,6,8,10], row_ids
#
#    row = rows(:"row_#{row_ids.first}")
#    row.destory
#
#    row_ids = Row.sort(row_ids)
#    asset_equal [4,2,5,3,6,1,7,8,10], row_ids
#  end
    
end
