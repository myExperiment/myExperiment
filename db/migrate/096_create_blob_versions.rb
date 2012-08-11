# myExperiment: db/migrate/096_create_blob_versions.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateBlobVersions < ActiveRecord::Migration

  def self.up
    create_table :blob_versions do |t|
      t.integer  "blob_id"
      t.integer  "version"
      t.text     "revision_comments"
      t.string   "title"
      t.text     "body"
      t.text     "body_html"
      t.integer  "content_type_id"
      t.integer  "content_blob_id"
      t.string   "local_name"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_column :blobs, :current_version, :integer

    execute "UPDATE blobs SET current_version = 1"

    execute "INSERT INTO blob_versions (blob_id, version, title, body, body_html, content_type_id, content_blob_id, local_name, created_at, updated_at) SELECT id, 1, title, body, body_html, content_type_id, content_blob_id, local_name, created_at, updated_at FROM blobs"
  end

  def self.down
    remove_column :blobs, :current_version

    drop_table :blob_versions
  end
end

