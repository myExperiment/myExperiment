class AddFileExtToWorkflow < ActiveRecord::Migration
  def self.up
#   add_column :workflows, :file_ext, :string
#   add_column :workflow_versions, :file_ext, :string

    # Currently, we assume that all workflows are scufl workflows!
#   execute 'UPDATE workflows SET file_ext = "xml"'
#   execute 'UPDATE workflow_versions SET file_ext = "xml"'
  end

  def self.down
#   remove_column :workflows, :file_ext
#   remove_column :workflow_versions, :file_ext
  end
end
