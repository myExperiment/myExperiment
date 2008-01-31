# myExperiment: db/migrate/019_restful_authentication.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class RestfulAuthentication < ActiveRecord::Migration
  def self.up
    add_column :users, :username, :string
    add_column :users, :crypted_password, :string, :limit => 40
    add_column :users, :salt, :string, :limit => 40
    add_column :users, :remember_token, :string
    add_column :users, :remember_token_expires_at, :datetime
  end
  
  def self.down
    remove_column :users, :username
    remove_column :users, :crypted_password
    remove_column :users, :salt
    remove_column :users, :remember_token
    remove_column :users, :remember_token_expires_at
  end
end
