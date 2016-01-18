class AddDoiToWorkflowVersions < ActiveRecord::Migration
  def self.up
    add_column :workflow_versions, :doi, :string
  end

  def self.down
    remove_column :workflow_versions, :doi
  end
end
