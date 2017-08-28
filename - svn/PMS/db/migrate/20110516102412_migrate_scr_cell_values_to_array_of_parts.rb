class MigrateScrCellValuesToArrayOfParts < ActiveRecord::Migration
  def self.up
    scr_custom_fields = CustomFields::ScreenCombindedReference.find(:all)

    scr_cells = scr_custom_fields.collect{|cf| cf.cells }.flatten

    scr_cells.each do |c|
      screen_ids = c.value.delete(:screen_ids) || []
      option_screen_ids = c.value.delete(:option_screen_ids) || []

      parts = []

      (screen_ids + option_screen_ids).each do |s_id|
        part_type = screen_ids.include?(s_id) ? :screen : :option
        parts << { :delimiter => "-", :type => part_type, :screen_id => s_id }
      end

      c.value[:parts] = parts
      c.save
    end
  end

  def self.down
    scr_custom_fields = CustomFields::ScreenCombindedReference.find(:all)

    scr_cells = scr_custom_fields.collect{|cf| cf.cells }.flatten

    scr_cells.each do |c|
      parts = c.value.delete(:parts) || []

      screen_ids = []
      option_screen_ids = []

      parts.each do |p|
        case p[:type]
        when :screen
          screen_ids << p[:screen_id]
        when :option
          option_screen_ids << p[:screen_id]
        end
      end

      c.value[:screen_ids] = screen_ids
      c.value[:option_screen_ids] = option_screen_ids
      c.save
    end
  end
end
