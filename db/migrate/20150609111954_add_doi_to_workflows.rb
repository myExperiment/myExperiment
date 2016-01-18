class AddDoiToWorkflows < ActiveRecord::Migration
  def self.up
    add_column :workflows, :doi, :string
  end

  def self.down
    remove_column :workflows, :doi
  end
end
