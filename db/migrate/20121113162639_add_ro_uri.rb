class AddRoUri < ActiveRecord::Migration
  def self.up
    add_column :workflows, :ro_uri, :text
    add_column :blobs,     :ro_uri, :text
    add_column :packs,     :ro_uri, :text
  end

  def self.down
    remove_column :workflows, :ro_uri
    remove_column :blobs,     :ro_uri
    remove_column :packs,     :ro_uri
  end
end
