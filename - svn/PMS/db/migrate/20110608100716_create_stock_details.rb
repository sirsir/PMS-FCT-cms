class CreateStockDetails < ActiveRecord::Migration
  def self.up
    create_table :stock_details do |t|
      t.integer :stock_id
      t.string :transaction_type
      t.string :input_value
      t.string :number_transaction
      t.yaml :changable_key

      t.timestamps
    end
  end

  def self.down
    drop_table :stock_details
  end
end
