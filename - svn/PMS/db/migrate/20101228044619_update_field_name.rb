class UpdateFieldName < ActiveRecord::Migration
  def self.up
    all_fields = Field.find(:all)
      all_fields.each do |f|
        unless f.custom_field.nil?
          if f.custom_field.name == "Name"
            f.display_in_discription=(true)
            f.save
          end
       end
    end
  end

  def self.down
    all_fields = field.find(:all)
    description_id = Label.find(:first, :conditions=>["name = ? ","G_Description"])
    unless description_id.nil?
      all_fields.each do |f|
        if f.custom_field.name == "Name"
          f.display_flags.delete("#{description_id}")
          f.save
        end
      end
    end
  end
end
