# myExperiment: db/migrate/005_create_memberships.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateMemberships < ActiveRecord::Migration
  def self.up
    create_table :memberships do |t|
      t.column :user_id, :integer
      t.column :network_id, :integer
      t.column :created_at, :datetime
      t.column :accepted_at, :datetime
    end
  end

  def self.down
    drop_table :memberships
  end
end
