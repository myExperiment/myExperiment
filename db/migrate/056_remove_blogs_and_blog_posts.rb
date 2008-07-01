# myExperiment: db/migrate/056_remove_blogs_and_blog_posts.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class RemoveBlogsAndBlogPosts < ActiveRecord::Migration

  def self.up

    Contribution.find(:all).each do |c|
      c.destroy if c.contributable_type == 'Blog'
    end
      
    drop_table :blogs
    drop_table :blog_posts
  end

  def self.down
    create_table "blog_posts", :force => true do |t|
      t.column "blog_id",    :integer
      t.column "title",      :string
      t.column "body",       :text
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      t.column "body_html",  :text
    end

    create_table "blogs", :force => true do |t|
      t.column "contributor_id",   :integer
      t.column "contributor_type", :string
      t.column "title",            :string
      t.column "created_at",       :datetime
      t.column "updated_at",       :datetime
    end
  end
end
