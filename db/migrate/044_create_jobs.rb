class CreateJobs < ActiveRecord::Migration
  def self.up
    create_table :jobs do |t|
      t.column :title, :string
      
      t.column :description, :text
      t.column :description_html, :text
      
      t.column :experiment_id, :integer
      
      t.column :user_id, :integer
      
      t.column :runnable_id, :integer
      t.column :runnable_version, :integer
      t.column :runnable_type, :string
      
      t.column :runner_id, :integer
      t.column :runner_type, :string
      
      t.column :submitted_at, :datetime
      t.column :started_at, :datetime
      t.column :completed_at, :datetime
      
      t.column :last_status, :string
      t.column :last_status_at, :datetime
      
      t.column :job_uri, :string
      t.column :job_manifest, :binary, :limit => 104857600 # in bytes; = 100MB
      t.column :inputs_uri, :string
      t.column :inputs_data, :binary, :limit => 104857600 # in bytes; = 100MB
      t.column :outputs_uri, :string
      
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :jobs
  end
end
