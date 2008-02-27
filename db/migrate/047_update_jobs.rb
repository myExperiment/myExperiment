class UpdateJobs < ActiveRecord::Migration
  def self.up
    add_column :jobs, :parent_job_id, :integer
  end

  def self.down
    remove_column :jobs, :parent_job_id
  end
end
