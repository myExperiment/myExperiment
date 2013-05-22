class ModifyBlobsForContentBlobs < ActiveRecord::Migration
  def self.up
    add_column :blobs, :content_blob_id, :integer
  end

  def self.down
    remove_column :blobs, :content_blob_id
  end
end
