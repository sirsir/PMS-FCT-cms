class InitDateTimeFieldValue < ActiveRecord::Migration
  def self.up
    dt_custom_fields = CustomFields::DateTimeField.find(:all)

    dt_custom_fields.each do |dt_cf|
      dt_cf.value ||= {
        :format_date => :short_date,
        :format_time => :none
      }
      dt_cf.save
    end
  end

  def self.down
    #~ Do Nothing
  end
end
