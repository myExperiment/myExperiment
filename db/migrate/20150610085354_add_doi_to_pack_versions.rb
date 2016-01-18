class AddDoiToPackVersions < ActiveRecord::Migration
  def self.up
    add_column :pack_versions, :doi, :string
  end

  def self.down
    remove_column :pack_versions, :doi
  end
end
