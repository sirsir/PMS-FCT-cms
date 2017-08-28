class CreateHeaderDetailListScreen < ActiveRecord::Migration
  def self.up
    create_table :header_screens do |t|

      t.timestamps
    end

    create_table :detail_screens do |t|

      t.timestamps
    end

    create_table :list_screens do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :header_screens
    drop_table :detail_screens
    drop_table :list_screens
  end
end
