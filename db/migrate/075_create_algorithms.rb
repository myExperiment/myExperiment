# myExperiment: db/migrate/074_create_algorithms.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateAlgorithms < ActiveRecord::Migration
  def self.up
    create_table :algorithms do |t|
      t.column :contributor_id, :integer
      t.column :contributor_type, :string
      t.column :title, :string
      t.column :description, :text
      t.column :description_html, :text
      t.column :license, :string
      t.column :url, :text
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :algorithms
  end
end
