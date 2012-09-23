# myExperiment: db/migrate/20120921144930_update_oauth_tables.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class UpdateOauthTables < ActiveRecord::Migration
  def self.up
    add_column :oauth_tokens, :callback_url, :string
    add_column :oauth_tokens, :verifier, :string, :limit => 20
    add_column :oauth_tokens, :scope, :string
  end

  def self.down
    drop_column :oauth_tokens, :callback_url
    drop_column :oauth_tokens, :verifier
    drop_column :oauth_tokens, :scope
  end
end
