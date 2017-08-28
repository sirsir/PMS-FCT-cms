class AddColumnFieldName < ActiveRecord::Migration
  def self.up
    add_column(:fields,:name,:string)
    fields = Field.find(:all)
    
    fields.each do |f|
      f.name = f.id
      f.save
    end
  end

  def self.down
    remove_column(:fields,:name)
  end
end
