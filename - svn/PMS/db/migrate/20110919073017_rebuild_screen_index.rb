ApplicationController.enter_admin_mode

class RebuildScreenIndex < ActiveRecord::Migration
  def self.up
    screens = Screen.find(:all)
    screens.each do |s|
      s.rebuild_index
    end
  end

  def self.down
    screens = Screen.find(:all)
    screens.each do |s|
      VirtualMemory.store(:screen_index, s.id, nil)
    end
  end
end
