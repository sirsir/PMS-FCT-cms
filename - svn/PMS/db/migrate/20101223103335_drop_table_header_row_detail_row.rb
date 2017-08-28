class DropTableHeaderRowDetailRow < ActiveRecord::Migration
  def self.up
    drop_table(:header_rows)
    drop_table(:detail_rows)
  end

  def self.down
    create_table "header_rows", :force => true do |t|
      t.integer  "row_id",     :limit => 4
      t.datetime "created_at"
      t.datetime "updated_at"
    end

   add_index "header_rows", ["row_id"], :name => "IX_header_rows_row_id"

   create_table "detail_rows", :force => true do |t|
    t.integer  "row_id",        :limit => 4
    t.integer  "header_row_id", :limit => 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "detail_rows", ["header_row_id"], :name => "IX_detail_rows_header_row_id"
  add_index "detail_rows", ["row_id"], :name => "IX_detail_rows_row_id"

  end
end
