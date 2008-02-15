class CreateRemoteWorkflows < ActiveRecord::Migration
  def self.up
    create_table :remote_workflows do |t|
      t.column :workflow_id, :integer
      t.column :workflow_version, :integer
      t.column :taverna_enactor_id, :integer
      t.column :workflow_uri, :string
    end
  end

  def self.down
    drop_table :remote_workflows
  end
end
