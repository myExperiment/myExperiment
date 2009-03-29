# myExperiment: db/migrate/075_create_apps.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateApps < ActiveRecord::Migration
  def self.up
    create_table :apps do |t|
      t.column :contributor_id, :integer
      t.column :contributor_type, :string
      t.column :title, :string
      t.column :description, :text
      t.column :description_html, :text
      t.column :license, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :apps
  end
end
