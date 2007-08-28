class AddMessageBoards < ActiveRecord::Migration

def self.up
  create_table :boards, :force => true do |t|
    t.column :title, :string, :limit => 50, :default => ""
    t.column :body, :text, :default => ""
    t.column :created_at, :datetime, :null => false
    t.column :updated_at, :datetime, :null => false
    t.column :user_id, :integer, :default => 0, :null => false
    t.column :group_id, :integer, :default => 0, :null => false
  end

  add_index :boards, ["user_id"], :name => "fk_comments_user"

  create_table :replies, :force => true do |t|
    t.column :body, :text, :default => ""
    t.column :user_id, :integer, :default => 0, :null => false
    t.column :created_at, :datetime, :null => false
    t.column :updated_at, :datetime, :null => false
    t.column :board_id, :integer, :default => 0, :null => false
  end

end

def self.down
  drop_table :boards
  drop_table :replies
end

end
