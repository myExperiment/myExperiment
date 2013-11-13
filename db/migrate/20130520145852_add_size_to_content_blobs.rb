class AddSizeToContentBlobs < ActiveRecord::Migration
  def self.up
    add_column :content_blobs, :size, :integer
    execute "UPDATE content_blobs SET size = LENGTH(data);"
  end

  def self.down
    drop_column :content_blobs, :size
  end
end
