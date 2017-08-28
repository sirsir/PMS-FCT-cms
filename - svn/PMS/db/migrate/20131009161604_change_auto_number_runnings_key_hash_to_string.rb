class ChangeAutoNumberRunningsKeyHashToString < ActiveRecord::Migration
  def self.up
    delete_all

    change_column :auto_number_runnings, :key_hash, :string
  end

  def self.down
    delete_all

    change_column :auto_number_runnings, :key_hash, :integer
  end

  def self.delete_all
    ApplicationController.enter_admin_mode

    auto_number_runnings = AutoNumberRunning.find(:all)
    
    auto_number_runnings.each do |anr|
      rows = anr.custom_field.cells.collect{|c| c.row }
      
      has_error = false

      rows.each do |r|
        r.destroy
        
        has_error = !r.errors.empty?
        
        if has_error
          puts r.errors.full_messages.inspect
          break
        end
      end
      
      if has_error
        anr.key_hash = nil
        anr.save
      else
        anr.destroy
      end
    end
  end
end
