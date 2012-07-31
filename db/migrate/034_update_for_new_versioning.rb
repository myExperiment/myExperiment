class UpdateForNewVersioning < ActiveRecord::Migration
  def self.up
    rename_column :workflows, :version, :current_version
    
    add_column :workflow_versions, :image, :string
    add_column :workflow_versions, :svg, :string
    add_column :workflow_versions, :revision_comments, :text
  end

  def self.down
    rename_column :workflows, :current_version, :version
    
    remove_column :workflow_versions, :image
    remove_column :workflow_versions, :svg
    remove_column :workflow_versions, :revision_comments
  end
end
