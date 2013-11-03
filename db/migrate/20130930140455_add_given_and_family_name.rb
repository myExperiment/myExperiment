# myExperiment: db/migrate/20130930140455_add_given_and_family_name.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

class AddGivenAndFamilyName < ActiveRecord::Migration
  def self.up
    add_column :users, :given_name, :string
    add_column :users, :family_name, :string
  end

  def self.down
    remove_column :users, :given_name
    remove_column :users, :family_name
  end
end
