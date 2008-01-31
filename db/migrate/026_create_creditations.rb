# myExperiment: db/migrate/026_create_creditations.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateCreditations < ActiveRecord::Migration
  def self.up
    create_table :creditations do |t|
      t.column :creditor_id, :integer
      t.column :creditor_type, :string
      
      t.column :creditable_id, :integer
      t.column :creditable_type, :string
      
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :creditations
  end
end
