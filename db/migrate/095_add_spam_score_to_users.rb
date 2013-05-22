# myExperiment: db/migrate/095_add_spam_score_to_users.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class AddSpamScoreToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :spam_score, :integer
  end

  def self.down
    remove_column :users, :spam_score
  end
end
