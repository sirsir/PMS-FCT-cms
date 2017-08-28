class ChangeCustomFieldsValueReferenceValueScreenId < ActiveRecord::Migration
  def self.up
    reference_field_type = FieldType.find(:first, :conditions => [ "name = ?", "Reference"])
    if not reference_field_type.nil?
      custom_fields = CustomField.find(:all, :conditions => [ "field_type_id = ?", reference_field_type.id])
      custom_fields.each do |cf|
        cf.value[:screen_id] = cf.value[:screen_ids]
        cf.value.delete(:screen_ids)
        cf.save
      end
    end
  end

  def self.down
    reference_field_type = FieldType.find(:first, :conditions => [ "name = ?", "Reference"])
    if not reference_field_type.nil?
      custom_fields = CustomField.find(:all, :conditions => [ "field_type_id = ?", reference_field_type.id])
      custom_fields.each do |cf|
        cf.value[:screen_ids] = cf.value[:screen_id]
        cf.value.delete(:screen_id)
        cf.save
      end
    end
  end
end
