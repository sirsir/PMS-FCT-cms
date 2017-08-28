class MigrateStructureReferenceValue < ActiveRecord::Migration
  def self.up
    custom_field_refernces =  CustomFields::Reference.find(:all)
    custom_field_refernces.each do |cf|
      cell_references = Cell.find(:all, :conditions => ["field_id = #{cf.id}"])
      cell_references.each do |c|
        if !c.value.is_a?(HashWithIndifferentAccess) and !c.value.empty?
          value = c.value
          c.value = HashWithIndifferentAccess.new(:row_id => value)
          c.save
        end
      end
    end
  end

  def self.down
    custom_field_refernces =  CustomFields::Reference.find(:all)
    custom_field_refernces.each do |cf|
      cell_references = Cell.find(:all, :conditions => ["field_id = #{cf.id}"])
      cell_references.each do |c|
        if c.value.is_a?(HashWithIndifferentAccess)
          value = c.value
          c.value = value[:row_id]
          c.save
        end
      end
    end
  end
end
