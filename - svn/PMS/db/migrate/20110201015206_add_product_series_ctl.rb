
ENV['name_cf_id'] = "186"
class AddProductSeriesCtl < ActiveRecord::Migration
  def self.up
    product_series = Screen.find(:first, :conditions => ["name = 'PRODUCT_SERIES' "])
    product_type = Screen.find(:first, :conditions => ["name = 'PRODUCT_TYPE' "])
    name_cf = CustomField.find(:first, :conditions => ["name = 'name' "])

    product_type_rows = Row.find(:all, :conditions => ["screen_id = #{product_type.id}"])
    product_type_row = product_type_rows.collect{|r| r if r.cell(name_cf.id).value == "IAI"}.compact[0]

    row_model = "#{product_series.prefix}_row".classify.constantize
    row = row_model.new(:screen_id => product_series.id, :type => row_model)

    cell = Cell.new(:field_id => name_cf.id, :value => 'CTL')
    row.cells << cell
    row.load_cell_hash(cell)

    puts "product_type.reference_custom_field.id #{product_type.reference_custom_field.id.to_s}"
    cell = Cell.new(:field_id => product_type.reference_custom_field.id, :value => {:row_id => product_type_row.id.to_s})
    row.cells << cell
    row.load_cell_hash(cell)

    if row.save
      #~ Save the cells
      row.cells.each do |c|
        c.save
      end
    end
  end

  def self.down
     product_series = Screen.find(:first, :conditions => ["name = 'PRODUCT_SERIES' "])
     name_cf = CustomField.find(:first, :conditions => ["name = 'name' "])

     product_type_row = product_series.rows.collect{|r| r if r.cell(name_cf.id).value == "CTL"}.compact[0]
     product_type_row.destroy
  end

  if RAILS_ENV =~ /^development$/
    def self.up

    end

    def self.down

    end
  end
end