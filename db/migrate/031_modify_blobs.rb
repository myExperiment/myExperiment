
class ModifyBlobs < ActiveRecord::Migration
  def self.up
    rename_column :blobs, :description, :body
    add_column :blobs, :body_html, :text
  end

  def self.down
    rename_column :blobs, :body, :description
    remove_column :blobs, :body_html
  end
end
