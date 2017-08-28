class ClearTmpScreenPermissionsCache < ActiveRecord::Migration
  def self.up
    VirtualMemory.clear(:screen_permissions)
    VirtualMemory.clear(:field_permissions)
  end

  def self.down
  end
end
