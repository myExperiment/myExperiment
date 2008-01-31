# myExperiment: db/migrate/002_create_profiles.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateProfiles < ActiveRecord::Migration
  def self.up
    create_table :profiles do |t|
      t.column :user_id, :integer
      t.column :picture_id, :integer
      t.column :email, :string
      t.column :website, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      
      t.column :body, :text
      t.column :body_html, :text
    end
  end

  def self.down
    drop_table :profiles
  end
end
