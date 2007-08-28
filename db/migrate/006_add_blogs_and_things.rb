class AddBlogsAndThings < ActiveRecord::Migration

def self.up
  create_table :posts, :force => true do |t|
    t.column :title, :string, :limit => 50, :default => ""
    t.column :body, :text, :default => ""
    t.column :created_at, :datetime, :null => false
    t.column :updated_at, :datetime, :null => false
    t.column :user_id, :integer, :default => 0, :null => false
    t.column :blog_id, :integer, :default => 0, :null => false
  end

  add_index :posts, ["user_id"], :name => "fk_comments_user"

  create_table :blogs, :force => true do |t|
    t.column :title, :string, :limit => 50, :default => ""
  end

  create_table :pages, :force => true do |t|
    t.column :title, :string, :limit => 50, :default => ""
    t.column :body, :text, :default => ""
    t.column :created_at, :datetime, :null => false
    t.column :updated_at, :datetime, :null => false
    t.column :user_id, :integer, :default => 0, :null => false
  end

  add_index :pages, ["user_id"], :name => "fk_comments_user"



end

def self.down
  drop_table :posts

  drop_table :blogs

  drop_table :pages
end

end
