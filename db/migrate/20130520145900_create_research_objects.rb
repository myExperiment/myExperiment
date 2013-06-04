# myExperiment: db/migrate/20130520145900_create_research_objects.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

class CreateResearchObjects < ActiveRecord::Migration
  def self.up

    create_table "research_objects", :force => true do |t|
      t.string   "slug"
      t.integer  "version"
      t.string   "version_type"
      t.integer  "user_id"

      t.timestamps
    end

    create_table "resources" do |t|
      t.integer "research_object_id"
      t.integer "content_blob_id"
      t.string  "sha1", :limit => 40
      t.integer "size"
      t.string  "content_type"
      t.text    "path"
      t.string  "entry_name"
      t.string  "creator_uri"
      t.string  "proxy_in_path"
      t.string  "proxy_for_path"
      t.string  "ao_body_path"
      t.string  "resource_map_path"
      t.string  "aggregated_by_path"

      t.boolean "is_resource",     :default => false
      t.boolean "is_aggregated",   :default => false
      t.boolean "is_proxy",        :default => false
      t.boolean "is_annotation",   :default => false
      t.boolean "is_resource_map", :default => false
      t.boolean "is_folder",       :default => false
      t.boolean "is_folder_entry", :default => false
      t.boolean "is_root_folder",  :default => false

      t.timestamps
    end

    create_table "annotation_resources" do |t|
      t.integer "research_object_id"
      t.integer "annotation_id"
      t.string  "resource_path"
    end

    add_column :packs, :ro_uri, :text
    add_column :packs, :research_object_id, :text
    add_column :pack_contributable_entries, :resource_path, :text
    add_column :pack_remote_entries, :resource_path, :text
  end

  def self.down
    drop_table :research_objects
    drop_table :resources
    drop_table :annotation_resources

    remove_column :packs, :ro_uri
    remove_column :packs, :research_object_id
    remove_column :pack_contributable_entries, :resource_path
    remove_column :pack_remote_entries, :resource_path
  end

end
