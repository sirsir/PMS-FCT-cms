class CreateRowsSessions < ActiveRecord::Migration
  def self.up
    create_table:rows_sessions  ,:id => false, :force => true do |t|
      t.integer :session_id
      t.integer :row_id
      
      t.timestamps
    end
  end

  def self.down
    drop_table :rows_sessions
  end
end
