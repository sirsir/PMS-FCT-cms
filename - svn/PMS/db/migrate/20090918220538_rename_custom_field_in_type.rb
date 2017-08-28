class RenameCustomFieldInType < ActiveRecord::Migration
  def self.up
    CustomField.inheritance_column = "type_"
    custom_fields = CustomField.find(:all)
    custom_fields.each {|cf|
      cf[:type] =cf[:type].gsub(
        "CustomField",
        (cf[:type] == "DateTimeCustomField") ? "Field" : ""
      )
      cf[:type] = "CustomFields::#{cf[:type]}"
      cf.save
    }
  end

  def self.down
    CustomField.inheritance_column = "type_"
    custom_fields = CustomField.find(:all)
    custom_fields.each {|cf|
      cf[:type] =cf[:type].gsub("CustomFields::::", "")
      if cf[:type] == "DateTimeField"
        cf[:type] =cf[:type].gsub("Field", "CustomField")
      else
        cf[:type] = "#{cf[:type]}#{"CustomField"}"
      end
      cf.save
    }
  end
end
