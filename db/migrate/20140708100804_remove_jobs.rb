class RemoveJobs < ActiveRecord::Migration
  def self.up
    drop_table :jobs
  end

  def self.down
  end
end
