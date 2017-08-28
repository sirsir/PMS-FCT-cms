class CreateStockTransactions < ActiveRecord::Migration
  def self.up
    create_table :stock_transactions do |t|
      t.datetime :transaction_at
      t.string :type
      t.yaml :value
      t.integer :reason_row_id
      t.string :remark

      t.timestamps
    end
  end

  def self.down
    drop_table :stock_transactions
  end
end
