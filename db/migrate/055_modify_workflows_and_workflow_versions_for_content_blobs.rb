class ModifyWorkflowsAndWorkflowVersionsForContentBlobs < ActiveRecord::Migration
  def self.up
    add_column :workflows, :content_blob_id, :integer
    add_column :workflow_versions, :content_blob_id, :integer
  end

  def self.down
    remove_column :workflows, :content_blob_id
    remove_column :workflow_versions, :content_blob_id
  end
end
