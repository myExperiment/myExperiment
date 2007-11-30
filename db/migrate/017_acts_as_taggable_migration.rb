# myExperiment: test/functional/friendships_controller_test.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class ActsAsTaggableMigration < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.column :name, :string
      t.column :taggings_count, :integer, :default => 0, :null => false
    end
    
    add_index :tags, :name 
    add_index :tags, :taggings_count
    
    create_table :taggings do |t|
      t.column :tag_id, :integer
      t.column :taggable_id, :integer
      t.column :taggable_type, :string
      
      # added by Mark Borkum (mib104@ecs.soton.ac.uk)
      t.column :user_id, :integer
      t.column :created_at, :datetime
    end
    
    # Find objects for a tag
    add_index :taggings, [:tag_id, :taggable_type] 
    add_index :taggings, [:user_id, :tag_id, :taggable_type]
    # Find tags for an object 
    add_index :taggings, [:taggable_id, :taggable_type] 
    add_index :taggings, [:user_id, :taggable_id, :taggable_type]
  end
  
  def self.down
    drop_table :tags
    drop_table :taggings
  end
end
