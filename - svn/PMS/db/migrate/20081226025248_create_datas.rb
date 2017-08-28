class CreateDatas < ActiveRecord::Migration
  def self.up
    create_table :datas do |t|
      t.integer :row_id
      t.integer :field_id
      t.string :value

      t.timestamps
    end
  end

  def self.down
    drop_table :datas
  end
end
