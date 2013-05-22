# myExperiment: db/migrate/097_create_pack_versions.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreatePackVersions < ActiveRecord::Migration

  def self.up
    create_table :pack_versions do |t|
      t.integer  "pack_id"
      t.integer  "version"
      t.text     "revision_comments"
      t.string   "title"
      t.text     "description"
      t.text     "description_html"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_column :packs, :current_version, :integer
    add_column :pack_contributable_entries, :version, :integer
    add_column :pack_remote_entries, :version, :integer
  end

  def self.down
    remove_column :packs, :current_version
    remove_column :pack_contributable_entries, :version
    remove_column :pack_remote_entries, :version

    drop_table :pack_versions
  end
end

