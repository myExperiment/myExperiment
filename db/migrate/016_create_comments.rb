# myExperiment: db/migrate/016_create_comments.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateComments < ActiveRecord::Migration
  def self.up
    create_table "comments", :force => true do |t|
      t.column "title", :string, :limit => 50, :default => ""
      t.column "comment", :text, :default => ""
      t.column "created_at", :datetime, :null => false
      t.column "commentable_id", :integer, :default => 0, :null => false
      t.column "commentable_type", :string, :limit => 15, :default => "", :null => false
      t.column "user_id", :integer, :default => 0, :null => false
    end
  
    add_index "comments", ["user_id"], :name => "fk_comments_user"
  end

  def self.down
    drop_table :comments
  end
end
