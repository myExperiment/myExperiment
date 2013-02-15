# myExperiment: db/migrate/20130215162325_change_runner_passwords.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

class ChangeRunnerPasswords < ActiveRecord::Migration
  def self.up
    remove_column :taverna_enactors, :crypted_password
    add_column    :taverna_enactors, :password, :string
  end

  def self.down
    add_column    :taverna_enactors, :crypted_password, :string
    remove_column :taverna_enactors, :password
  end
end
