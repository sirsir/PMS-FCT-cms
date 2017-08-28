class CreateStockItems < ActiveRecord::Migration
  def self.up
    registered_field_count = 10
    
    create_table :stock_items do |t|
      (0..registered_field_count-1).each do |i|
        t.integer "stock_key_id_#{i.to_s}"
      end
      
      t.datetime :take_in_date
      t.float :take_in_qty
      t.float :cost
      t.float :booked
      
      t.timestamps
    end
  end

  def self.down
    drop_table :stock_items
  end
end
