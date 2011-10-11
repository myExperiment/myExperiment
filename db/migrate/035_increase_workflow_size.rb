
class IncreaseWorkflowSize < ActiveRecord::Migration
  def self.up
#   rename_column :workflows, :scufl, :temp
#   add_column :workflows, :scufl, :binary, :limit => 1073741824
#   execute 'UPDATE workflows SET scufl = temp'
#   remove_column :workflows, :temp

#   execute 'ALTER TABLE workflow_versions CHANGE COLUMN scufl scufl LONGBLOB'

  end

  def self.down
#   rename_column :workflows, :scufl, :temp
#   add_column :workflows, :scufl, :binary
#   execute 'UPDATE workflows SET scufl = temp'
#   remove_column :workflows, :temp

#   execute 'ALTER TABLE workflow_versions CHANGE COLUMN scufl scufl BLOB'

  end
end
