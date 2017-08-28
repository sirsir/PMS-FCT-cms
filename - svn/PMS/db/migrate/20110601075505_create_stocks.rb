class CreateStocks < ActiveRecord::Migration
  def self.up
    create_table :stocks do |t|
      t.string :name
      t.integer :label_id
      t.string :descr
      t.yaml :value
      t.yaml :keys
      t.yaml :auto_booking
      t.yaml :hidden
      t.string :remark

      t.timestamps
    end
  end

  def self.down
    drop_table :stocks
  end
end
