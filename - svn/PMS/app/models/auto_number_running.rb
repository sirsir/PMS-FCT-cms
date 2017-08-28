require 'digest/md5'

class AutoNumberRunning < ActiveRecord::Base
  belongs_to :custom_field

  class << self

    def key_hash(format_key, format_value)
      Digest::MD5.hexdigest("key => #{format_key}, value => #{format_value}")
    end

  end
end
