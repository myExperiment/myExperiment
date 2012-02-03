class MoveBlobDataToContentBlobs < ActiveRecord::Migration
  def self.up

#   Blob.find(:all).each do |b|
#     b.content_blob = ContentBlob.new(:data => b.data)
#     b.save
#   end

#   remove_column :blobs, :data
  end

  def self.down
#   add_column :blobs, :data, :binary, :limit => 1073741824

#   execute 'UPDATE blobs,content_blobs SET blobs.data = content_blobs.data WHERE blobs.content_blob_id = content_blobs.id'
  end
end
