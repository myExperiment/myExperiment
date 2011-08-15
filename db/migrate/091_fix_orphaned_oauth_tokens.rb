# myExperiment: db/migrate/091_fix_orphaned_oauth_tokens.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

class FixOrphanedOauthTokens < ActiveRecord::Migration
  def self.up

    OauthToken.find(:all).each do |t|
      if t.client_application.nil?
        t.destroy()
      end
    end
  end

  def self.down
  end
end
