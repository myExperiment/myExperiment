class AddWorkflowLicenses < ActiveRecord::Migration
  def self.up
    add_column :workflows, :license, :string, :limit => 10, :null => false, :default => "a"
  end

  def self.down
    remove_column :workflows, :license
  end
end
