class CreateListRows < ActiveRecord::Migration
  def self.up
    create_table :list_rows do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :list_rows
  end
end
