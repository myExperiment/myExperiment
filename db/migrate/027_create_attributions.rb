# myExperiment: db/migrate/027_create_attributions.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateAttributions < ActiveRecord::Migration
  def self.up
    create_table :attributions do |t|
      t.column :attributor_id, :integer
      t.column :attributor_type, :string
      
      t.column :attributable_id, :integer
      t.column :attributable_type, :string
      
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :attributions
  end
end
