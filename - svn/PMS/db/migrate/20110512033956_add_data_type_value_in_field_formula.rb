class AddDataTypeValueInFieldFormula < ActiveRecord::Migration
  def self.up
    fomula_fields = Fields::Formula.find(:all)
    fomula_fields.each do |ff|
      ff.value[:data_type] = :number

      ff.save
    end
  end

  def self.down
  end
end
