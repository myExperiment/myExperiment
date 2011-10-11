# Add content_type to workflows

class AddTypeToWorkflows < ActiveRecord::Migration
  def self.up
#   add_column :workflows, :content_type, :string
#   add_column :workflow_versions, :content_type, :string

#   # Currently, all workflows are scufl workflows
#   execute 'UPDATE workflows SET content_type = "application/vnd.taverna.scufl+xml"'
#   execute 'UPDATE workflow_versions SET content_type = "application/vnd.taverna.scufl+xml"'
  end

  def self.down
#   remove_column :workflows, :content_type
#   remove_column :workflow_versions, :content_type
  end
end
