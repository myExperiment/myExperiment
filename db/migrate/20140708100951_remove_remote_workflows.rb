class RemoveRemoteWorkflows < ActiveRecord::Migration
  def self.up
    drop_table :remote_workflows
  end

  def self.down
  end
end
