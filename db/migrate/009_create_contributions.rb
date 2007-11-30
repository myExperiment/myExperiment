# myExperiment: db/migrate/009_create_contributions.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateContributions < ActiveRecord::Migration
  def self.up
    create_table :contributions do |t|
      t.column :contributor_id, :integer
      t.column :contributor_type, :string
      
      t.column :contributable_id, :integer
      t.column :contributable_type, :string
      
      t.column :policy_id, :integer
      
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :contributions
  end
end
