class AddCustomFieldSingleCheckBox < ActiveRecord::Migration
  def self.up
    check_box = CustomFields::CheckBox.find(:all)
    check_box.each do |cb|
      cb.value[:type] = :multi.to_s

      cb.save
    end
  end

  def self.down
  end
end
