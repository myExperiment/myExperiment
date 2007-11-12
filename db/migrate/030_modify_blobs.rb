
class ModifyBlobs < ActiveRecord::Migration
  def self.up
    add_column :blobs, :license, :string, :limit => 10, :null => false, :default => "by-nd"
  end

  def self.down
    remove_column :blobs, :license
  end
end
