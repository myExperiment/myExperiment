class CreateBlogs < ActiveRecord::Migration
  def self.up
  create_table :blogs, :force => true do |t|
    t.column :title, :string, :limit => 50, :default => ""
    t.column :body, :text, :default => "", :null => false
    t.column :user_id, :integer, :default => 0, :null => false
    t.column :created_at, :datetime, :null => false
  end
  end

  def self.down
    drop_table :blogs
  end
end
