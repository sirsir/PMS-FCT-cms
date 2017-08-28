class ChangeFormatCellValueOfAutoNumberingCustomField < ActiveRecord::Migration
  def self.up
    auto_numbering_custom_fields = CustomFields::AutoNumbering.find(:all)

    auto_numbering_custom_fields.each do |cf|
      cf.cells.each do |c|
        value = c.value

        c.value = {}
        c.value[:text] = value

        c.save
      end
    end
  end

  def self.down
  end
end
