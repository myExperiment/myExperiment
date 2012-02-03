class AddLastEditedByToWorkflows < ActiveRecord::Migration
  def self.up
#   add_column :workflows, :last_edited_by, :string
#   add_column :workflow_versions, :last_edited_by, :string
    
#   execute 'UPDATE workflows SET last_edited_by=contributor_id'
#   execute 'UPDATE workflow_versions SET last_edited_by=contributor_id'
  end

  def self.down
#   remove_column :workflows, :last_edited_by
#   remove_column :workflow_versions, :last_edited_by
  end
end
