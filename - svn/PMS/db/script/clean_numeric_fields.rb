class ApplicationController
  class << self
    def admin_mode?
      true
    end
  end
end

begin
  CustomFields::NumericField.cleanse_all

  puts "Done"
end