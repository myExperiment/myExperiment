# myExperiment: db/migrate/012_create_blobs.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateBlobs < ActiveRecord::Migration
  def self.up
#   create_table :blobs do |t|
#     t.column :contributor_id, :integer
#     t.column :contributor_type, :string
#     t.column :local_name, :string
#     t.column :content_type, :string
#     t.column :data, :binary
#     t.column :created_at, :datetime
#     t.column :updated_at, :datetime
#   end
  end

  def self.down
#   drop_table :blobs
  end
end
