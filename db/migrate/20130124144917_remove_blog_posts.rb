class RemoveBlogPosts < ActiveRecord::Migration
  def self.up
    drop_table :blog_posts
  end

  def self.down
    create_table :blog_posts do |t|
      t.column :blog_id, :integer
      t.column :title, :string
      t.column :body, :text
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :body_html, :text
    end
  end
end
