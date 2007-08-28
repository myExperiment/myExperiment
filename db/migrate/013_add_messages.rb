class AddMessages < ActiveRecord::Migration
  def self.up
    create_table :messages, :force => true do |t|
      t.column "subject", :string
      t.column "body",    :text
      t.column "reply_id", :integer
      t.column "from_id", :integer, :null => false
      t.column "to_id",   :integer, :null => false
      t.column "created_at",  :datetime
      t.column "read_at", :datetime
    end

    add_index :messages, ["from_id"], :name => "fk_messages_from"
    add_index :messages, ["to_id"], :name => "fk_messages_to"

  end

  def self.down
    drop_table :messages
  end
end
