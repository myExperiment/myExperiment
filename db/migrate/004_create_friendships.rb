# myExperiment: db/migrate/004_create_friendships.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateFriendships < ActiveRecord::Migration
  def self.up
    create_table :friendships do |t|
      t.column :user_id, :integer
      t.column :friend_id, :integer
      t.column :created_at, :datetime
      t.column :accepted_at, :datetime
    end
  end

  def self.down
    drop_table :friendships
  end
end
