class SetRefAttFieldsReferenceFieldId < ActiveRecord::Migration
  def self.up
    reference_attribute_fields = Fields::ReferenceAttribute.find(:all)

    reference_attribute_fields.each do |raf|
      source_field = raf.source_field
      if source_field
        source_screen = source_field.screen

        reference_custom_field_ids = source_screen.reference_custom_field_ids
        
        reference_field = raf.screen.fields.select{|f| reference_custom_field_ids.include?(f.custom_field_id) }.first


        unless reference_field.nil?
          raf.value[:reference_field_id] ||= reference_field.id

          raf.save
        end
      end
    end
  end

  def self.down
  end
end
