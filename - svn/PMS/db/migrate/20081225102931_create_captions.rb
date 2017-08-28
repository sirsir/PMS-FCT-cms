class CreateCaptions < ActiveRecord::Migration
  def self.up
    create_table :captions do |t|
      t.integer :label_id
      t.integer :language_id
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :captions
  end
end
