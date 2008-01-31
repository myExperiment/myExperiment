# myExperiment: db/migrate/018_savage_beast_tables.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class SavageBeastTables < ActiveRecord::Migration
  def self.up
    Rails.plugins["savage_beast"].migrate(49)
    
    add_column :users, :posts_count, :integer, :default => 0
    add_column :users, :last_seen_at, :datetime
  end

  def self.down
    Rails.plugins["savage_beast"].migrate(0)
    
    remove_column :users, :posts_count
    remove_column :users, :last_seen_at
  end
end
