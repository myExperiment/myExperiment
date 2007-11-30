# myExperiment: db/migrate/007_create_networks.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateNetworks < ActiveRecord::Migration
  def self.up
    create_table :networks do |t|
      t.column :user_id, :integer
      t.column :title, :string
      t.column :unique_name, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :description, :text
      t.column :description_html, :text
    end
  end

  def self.down
    drop_table :networks
  end
end
