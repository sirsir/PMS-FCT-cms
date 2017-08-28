class CreateAllIndexes < ActiveRecord::Migration
  def self.up
    indexes do |table_name, columns|
      add_index table_name, columns, :name => "IX_#{table_name}_#{columns.join("_")}", :unique => false
    end
  end

  def self.down
    indexes do |table_name, columns|
      remove_index table_name, :name => "IX_#{table_name}_#{columns.join("_")}"
    end
  end

  def self.indexes
    list.each do |t|
      t[:fields].each do |columns|
        yield t[:name], columns
      end
    end
  end

  def self.list
    [
      {:name => :captions,       :fields => [[:label_id] ,[:language_id] ,[:label_id, :language_id]]},
      {:name => :cells,          :fields => [[:row_id] ,[:field_id] ,[:row_id, :field_id]]},
      {:name => :custom_fields,  :fields => [[:name] ,[:custom_field_id] ,[:type]]},
      {:name => :detail_rows,    :fields => [[:row_id] ,[:header_row_id]]},
      {:name => :fields,         :fields => [[:screen_id] ,[:custom_field_id] ,[:type]]},
      {:name => :fields_reports, :fields => [[:field_id, :report_id]]},
      {:name => :header_rows,    :fields => [[:row_id]]},
      {:name => :labels,         :fields => [[:name]]},
      {:name => :languages,      :fields => [[:name]]},
      {:name => :permissions,    :fields => [[:type]   ,[:role_id,:screen_id] ,[:role_id,:field_id]   ,[:user_id,:screen_id] ,[:user_id,:field_id]]},
      {:name => :reports,        :fields => [[:name]]},
      {:name => :roles,          :fields => [[:name]]},
      {:name => :roles_users,    :fields => [[:role_id, :user_id]   ]},
      {:name => :rows,           :fields => [[:screen_id] ,[:row_type] ,[:delete_flag]]},
      {:name => :rows_sessions,  :fields => [[:session_id, :row_id]]},
      {:name => :screens,        :fields => [[:name] ,[:screen_id]   ,[:system] ,[:action, :controller] ,[:type] ]},
      {:name => :sessions,       :fields => [[:session_id]]},
      {:name => :users,          :fields => [[:login]]}
    ]
  end
end
