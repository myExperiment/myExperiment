# myExperiment: db/migrate/018_savage_beast_tables.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class SavageBeastTables < ActiveRecord::Migration
  def self.up

#   create_table "forums", :force => true do |t|
#     t.column "name",             :string
#     t.column "contributor_id",   :integer
#     t.column "contributor_type", :string
#     t.column "description",      :string
#     t.column "topics_count",     :integer, :default => 0
#     t.column "posts_count",      :integer, :default => 0
#     t.column "position",         :integer
#     t.column "description_html", :text
#   end

#   create_table "moderatorships", :force => true do |t|
#     t.column "forum_id", :integer
#     t.column "user_id",  :integer
#   end

#   add_index "moderatorships", ["forum_id"], :name => "index_moderatorships_on_forum_id"

#   create_table "monitorships", :force => true do |t|
#     t.column "topic_id", :integer
#     t.column "user_id",  :integer
#     t.column "active",   :boolean, :default => true
#   end

#   create_table "posts", :force => true do |t|
#     t.column "user_id",    :integer
#     t.column "topic_id",   :integer
#     t.column "body",       :text
#     t.column "created_at", :datetime
#     t.column "updated_at", :datetime
#     t.column "forum_id",   :integer
#     t.column "body_html",  :text
#   end

#   add_index "posts", ["forum_id", "created_at"], :name => "index_posts_on_forum_id"
#   add_index "posts", ["user_id", "created_at"], :name => "index_posts_on_user_id"
#   
#   create_table "topics", :force => true do |t|
#     t.column "forum_id",     :integer
#     t.column "user_id",      :integer
#     t.column "title",        :string
#     t.column "created_at",   :datetime
#     t.column "updated_at",   :datetime
#     t.column "hits",         :integer,  :default => 0
#     t.column "sticky",       :integer,  :default => 0
#     t.column "posts_count",  :integer,  :default => 0
#     t.column "replied_at",   :datetime
#     t.column "locked",       :boolean,  :default => false
#     t.column "replied_by",   :integer
#     t.column "last_post_id", :integer
#   end

#   add_index "topics", ["forum_id"], :name => "index_topics_on_forum_id"
#   add_index "topics", ["forum_id", "sticky", "replied_at"], :name => "index_topics_on_sticky_and_replied_at"
#   add_index "topics", ["forum_id", "replied_at"], :name => "index_topics_on_forum_id_and_replied_at"

#   add_column :users, :posts_count, :integer, :default => 0
    add_column :users, :last_seen_at, :datetime
  end

  def self.down
#   drop_table :forums
#   drop_table :moderatorships
#   drop_table :monitorships
#   drop_table :posts
#   drop_table :topics
#   
#   remove_column :users, :posts_count
    remove_column :users, :last_seen_at
  end
end
