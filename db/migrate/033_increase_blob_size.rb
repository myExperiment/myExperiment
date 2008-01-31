
class IncreaseBlobSize < ActiveRecord::Migration
  def self.up
    rename_column :blobs, :data, :temp
    add_column :blobs, :data, :binary, :limit => 1073741824
    execute 'UPDATE blobs SET data = temp'
    remove_column :blobs, :temp
  end

  def self.down
    rename_column :blobs, :data, :temp
    add_column :blobs, :data, :binary
    execute 'UPDATE blobs SET data = temp'
    remove_column :blobs, :temp
  end
end
