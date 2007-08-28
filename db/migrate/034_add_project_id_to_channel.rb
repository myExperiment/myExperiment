class AddProjectIdToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :project_id, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :channels, :project_id
  end
end
