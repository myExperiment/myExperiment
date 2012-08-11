# myExperiment: db/migrate/094_add_account_status_to_users.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class AddAccountStatusToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :account_status, :string
  end

  def self.down
    remove_column :users, :account_status
  end
end

