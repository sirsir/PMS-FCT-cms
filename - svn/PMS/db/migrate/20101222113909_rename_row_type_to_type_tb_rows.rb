class RenameRowTypeToTypeTbRows < ActiveRecord::Migration
  def self.up
    rename_column(:rows, :row_type, :type)
    #migrate data type
    screens = Screen.find(:all)
    screens.each do |s|
      puts s.prefix 
      next if s.system? or s.prefix == "" or s.prefix == "MenuGroup"
      row_model = "#{s.prefix}_row".classify.constantize
      execute "
update rows
set type = '#{row_model}'
where screen_id = #{s.id}
      "
    end
  end

  def self.down
    rename_column(:rows, :type, :row_type)
  end
end
