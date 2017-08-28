class CGI
  class Session
    def active_screen
      @active_screen ||= Screen.find(self[:screen_id]) if self[:screen_id].to_i > 0
    end

    def active_screen=(value)
      @active_screen = nil

      case value
      when Screen
        self[:screen_id] = value.id
      when Fixnum
        self[:screen_id] = value
      else
        self[:screen_id] = nil
      end
    end
  end
end