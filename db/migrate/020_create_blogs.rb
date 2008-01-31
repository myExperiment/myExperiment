# myExperiment: db/migrate/020_create_blogs.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateBlogs < ActiveRecord::Migration
  def self.up
    create_table :blogs do |t|
      t.column :contributor_id, :integer
      t.column :contributor_type, :string
      t.column :title, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :blogs
  end
end
