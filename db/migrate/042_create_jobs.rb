class CreateJobs < ActiveRecord::Migration
  def self.up
    create_table :jobs do |t|
      t.column :user_id, :integer, :default => 0, :null => false
      t.column :workflow_id, :integer
      t.column :inputs, :text
      t.column :outputs, :text
      t.column :created_at, :datetime, :null => false
      t.column :started_at, :datetime
      t.column :finished_at, :datetime
      t.column :status, :string
      t.column :server_job, :string
    end
    
    create_table :remote_workflows do |t|
      t.column :workflow_id, :integer
      t.column :server, :string
      t.column :workflow_location, :string
    end
  end

  def self.down
    drop_table :jobs
    drop_table :remote_workflows
  end
end
