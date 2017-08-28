require 'thread'

class Session < ActiveRecord::Base
  has_and_belongs_to_many :rows
  before_destroy :clear_vm

  serialize :data

  class << self # Class methods
    def running?
      @@running ||= false
    end
    
    def purge_days
      1
    end

    def purge()
      return if running?
      
      @@running = true

      sessions = Session.find(:all)

      check_point = DateTime.now - purge_days

      sessions.each do |s|
        if s.updated_at < check_point
          s.destroy
        end
      end

      @@running = false
    end
  end

  def clear_vm
    VirtualMemory::store(:session, self.session_id, nil)
  end
end
