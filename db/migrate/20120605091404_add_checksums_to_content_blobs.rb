# myExperiment: db/migrate/20120605091404_add_checksums_to_content_blobs.rb
# 
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class AddChecksumsToContentBlobs < ActiveRecord::Migration
  def self.up
    add_column :content_blobs, :md5,  :string, :limit => 32
    add_column :content_blobs, :sha1, :string, :limit => 40
  end

  def self.down
    remove_column :content_blobs, :md5
    remove_column :content_blobs, :sha1
  end
end
