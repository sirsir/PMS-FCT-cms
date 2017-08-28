# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140115102102) do

  create_table "auto_number_runnings", :force => true do |t|
    t.integer  "custom_field_id"
    t.string   "key_hash"
    t.integer  "current"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "auto_number_runnings", ["custom_field_id", "key_hash"], :name => "IX_auto_number_runnings_custom_field_id_key_hash"
  add_index "auto_number_runnings", ["custom_field_id"], :name => "IX_auto_number_runnings_custom_field_id"

  create_table "calendar_values", :force => true do |t|
    t.integer  "cell_id"
    t.datetime "date_time"
    t.integer  "row_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "calendar_values", ["cell_id", "date_time"], :name => "IX_calendar_values_cell_id_date_time"
  add_index "calendar_values", ["cell_id"], :name => "IX_calendar_values_cell_id"

  create_table "captions", :force => true do |t|
    t.integer  "label_id"
    t.integer  "language_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "captions", ["label_id", "language_id"], :name => "IX_captions_label_id_language_id"
  add_index "captions", ["label_id"], :name => "IX_captions_label_id"
  add_index "captions", ["language_id"], :name => "IX_captions_language_id"

  create_table "cells", :force => true do |t|
    t.integer  "row_id"
    t.integer  "field_id"
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cells", ["field_id"], :name => "IX_cells_field_id"
  add_index "cells", ["row_id", "field_id"], :name => "IX_cells_row_id_field_id"
  add_index "cells", ["row_id"], :name => "IX_cells_row_id"

  create_table "custom_fields", :force => true do |t|
    t.string   "name"
    t.integer  "custom_field_id"
    t.string   "descr"
    t.integer  "label_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "value"
    t.text     "display_flags"
    t.string   "type",            :default => "CustomField", :null => false
  end

  add_index "custom_fields", ["custom_field_id"], :name => "IX_custom_fields_custom_field_id"
  add_index "custom_fields", ["name"], :name => "IX_custom_fields_name"
  add_index "custom_fields", ["type"], :name => "IX_custom_fields_type"

  create_table "date_time_range_values", :force => true do |t|
    t.integer  "cell_id"
    t.datetime "date_time_from"
    t.datetime "date_time_to"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "date_time_range_values", ["cell_id"], :name => "IX_date_time_range_values_cell_id"

  create_table "detail_screens", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "field_filters", :force => true do |t|
    t.integer  "report_request_id"
    t.integer  "field_id"
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "reference_screen_index"
  end

  add_index "field_filters", ["field_id"], :name => "IX_field_filters_field_id"
  add_index "field_filters", ["report_request_id"], :name => "IX_field_filters_report_request_id"

  create_table "field_report_filters", :force => true do |t|
    t.integer  "report_id"
    t.integer  "field_id"
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "reference_screen_index"
  end

  add_index "field_report_filters", ["field_id"], :name => "IX_field_report_filters_field_id"
  add_index "field_report_filters", ["report_id"], :name => "IX_field_report_filters_request_id"

  create_table "fields", :force => true do |t|
    t.integer  "screen_id"
    t.integer  "custom_field_id"
    t.integer  "display_seq"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mandatory_check"
    t.integer  "unique"
    t.text     "display_flags"
    t.string   "type",            :default => "Fields::Data", :null => false
    t.text     "value"
    t.integer  "label_id"
    t.string   "name"
    t.integer  "field_id"
    t.text     "sorting_order"
  end

  add_index "fields", ["custom_field_id"], :name => "IX_fields_custom_field_id"
  add_index "fields", ["screen_id"], :name => "IX_fields_screen_id"
  add_index "fields", ["type"], :name => "IX_fields_type"

  create_table "fields_reports", :force => true do |t|
    t.integer  "field_id",               :null => false
    t.integer  "report_id",              :null => false
    t.integer  "seq_no",                 :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "summarize"
    t.string   "location"
    t.text     "field_format"
    t.integer  "reference_screen_index"
    t.integer  "chart_axis_index"
    t.integer  "label_id"
    t.integer  "sorting_index"
    t.text     "percentage_weight"
    t.string   "field_type"
    t.text     "formula"
  end

  add_index "fields_reports", ["field_id"], :name => "IX_fields_reports_field_id"
  add_index "fields_reports", ["report_id"], :name => "IX_fields_reports_report_id"

  create_table "full_logs", :force => true do |t|
    t.integer  "row_id"
    t.integer  "seq_no"
    t.text     "action"
    t.string   "user"
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "header_screens", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "labels", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "labels", ["name"], :name => "IX_labels_name"

  create_table "languages", :force => true do |t|
    t.string   "name",       :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "languages", ["name"], :name => "IX_languages_name"

  create_table "list_rows", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "list_screens", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "menu_group_screens", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "numeric_field_values", :force => true do |t|
    t.integer  "cell_id"
    t.float    "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "numeric_field_values", ["cell_id"], :name => "IX_numeric_field_values_cell_id", :unique => true

  create_table "permissions", :force => true do |t|
    t.integer  "role_id"
    t.integer  "user_id"
    t.integer  "screen_id"
    t.integer  "field_id"
    t.text     "actions"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "permissions", ["role_id", "field_id"], :name => "IX_permissions_role_id_field_id"
  add_index "permissions", ["role_id", "screen_id"], :name => "IX_permissions_role_id_screen_id"
  add_index "permissions", ["type"], :name => "IX_permissions_type"
  add_index "permissions", ["user_id", "field_id"], :name => "IX_permissions_user_id_field_id"
  add_index "permissions", ["user_id", "screen_id"], :name => "IX_permissions_user_id_screen_id"

  create_table "report_request_cells", :force => true do |t|
    t.integer  "report_request_row_id"
    t.integer  "report_request_col_id"
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "report_request_cells", ["report_request_col_id"], :name => "IX_report_request_cells_report_request_col_id"
  add_index "report_request_cells", ["report_request_row_id"], :name => "IX_report_request_cells_report_request_row_id"

  create_table "report_request_cols", :force => true do |t|
    t.integer  "report_request_col_id"
    t.integer  "source_id"
    t.integer  "fields_report_id"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "report_request_id"
  end

  add_index "report_request_cols", ["fields_report_id"], :name => "IX_report_request_cols_fields_report_id"
  add_index "report_request_cols", ["report_request_col_id"], :name => "IX_report_request_cols_report_request_col_id"
  add_index "report_request_cols", ["source_id"], :name => "IX_report_request_cols_source_id"

  create_table "report_request_rows", :force => true do |t|
    t.integer  "report_request_row_id"
    t.integer  "row_id"
    t.integer  "report_request_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "reference_screen_index"
  end

  add_index "report_request_rows", ["report_request_id"], :name => "IX_report_request_rows_report_request_id"
  add_index "report_request_rows", ["report_request_row_id"], :name => "IX_report_request_rows_report_request_row_id"
  add_index "report_request_rows", ["row_id"], :name => "IX_report_request_rows_row_id"

  create_table "report_requests", :force => true do |t|
    t.string   "name"
    t.integer  "report_id"
    t.integer  "user_id"
    t.string   "remark"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "refresh_interval_index"
    t.datetime "last_run_at"
  end

  create_table "report_templates", :force => true do |t|
    t.integer  "screen_id"
    t.string   "name"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "file"
    t.string   "display",     :default => "edit"
    t.string   "output_type", :default => "pdf"
  end

  create_table "reports", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "descr"
    t.text     "reference_screen_ids"
    t.text     "criterias"
    t.text     "reference_screen_alias"
    t.string   "remark"
    t.text     "reference_screen_outer_joins"
    t.string   "grand_total"
    t.string   "cell_location"
  end

  add_index "reports", ["name"], :name => "IX_reports_name"

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.string   "descr"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name"], :name => "IX_roles_name"

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer  "role_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles_users", ["role_id", "user_id"], :name => "IX_roles_users_role_id_user_id"

  create_table "rows", :force => true do |t|
    t.integer  "screen_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "remark"
    t.string   "type"
    t.boolean  "delete_flag"
    t.integer  "row_id"
    t.text     "value"
  end

  add_index "rows", ["delete_flag"], :name => "IX_rows_delete_flag"
  add_index "rows", ["screen_id"], :name => "IX_rows_screen_id"
  add_index "rows", ["type"], :name => "IX_rows_row_type"

  create_table "rows_sessions", :id => false, :force => true do |t|
    t.integer  "session_id"
    t.integer  "row_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rows_sessions", ["session_id", "row_id"], :name => "IX_rows_sessions_session_id_row_id"

  create_table "screens", :force => true do |t|
    t.string   "name"
    t.integer  "screen_id"
    t.integer  "label_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "system"
    t.integer  "display_seq"
    t.string   "action"
    t.string   "controller"
    t.string   "type"
    t.integer  "alias_screen"
    t.integer  "relate_screen"
    t.text     "value"
    t.string   "icon"
    t.string   "page_size",     :default => "A4"
    t.string   "page_layout",   :default => "portrait"
  end

  add_index "screens", ["action", "controller"], :name => "IX_screens_action_controller"
  add_index "screens", ["name"], :name => "IX_screens_name"
  add_index "screens", ["screen_id"], :name => "IX_screens_screen_id"
  add_index "screens", ["system"], :name => "IX_screens_system"
  add_index "screens", ["type"], :name => "IX_screens_type"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "IX_sessions_session_id"
  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "stock_details", :force => true do |t|
    t.integer  "stock_id"
    t.string   "transaction_type"
    t.string   "input_value"
    t.string   "number_transaction"
    t.text     "changable_key"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stock_items", :force => true do |t|
    t.integer  "stock_key_id_0"
    t.integer  "stock_key_id_1"
    t.integer  "stock_key_id_2"
    t.integer  "stock_key_id_3"
    t.integer  "stock_key_id_4"
    t.integer  "stock_key_id_5"
    t.integer  "stock_key_id_6"
    t.integer  "stock_key_id_7"
    t.integer  "stock_key_id_8"
    t.integer  "stock_key_id_9"
    t.datetime "take_in_date"
    t.float    "take_in_qty"
    t.float    "cost"
    t.float    "booked"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stock_transactions", :force => true do |t|
    t.datetime "transaction_at"
    t.string   "type"
    t.text     "value"
    t.integer  "reason_row_id"
    t.string   "remark"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stocks", :force => true do |t|
    t.string   "name"
    t.integer  "label_id"
    t.string   "descr"
    t.text     "value"
    t.string   "remark"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sysdiagrams", :primary_key => "diagram_id", :force => true do |t|
    t.string  "name",         :limit => 128, :null => false
    t.integer "principal_id",                :null => false
    t.integer "version"
    t.binary  "definition"
  end

  add_index "sysdiagrams", ["principal_id", "name"], :name => "UK_principal_name", :unique => true

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "password"
    t.integer  "per_page"
    t.boolean  "disabled_flag",      :default => false, :null => false
    t.string   "encrypted_password"
    t.integer  "language_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["login"], :name => "IX_users_login"

end
