class RemoveExperiments < ActiveRecord::Migration
  def self.up
    drop_table :experiments
  end

  def self.down
  end
end
