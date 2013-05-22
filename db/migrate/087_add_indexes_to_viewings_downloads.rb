class AddIndexesToViewingsDownloads < ActiveRecord::Migration
  def self.up

    add_index :viewings, ["contribution_id"]
#   add_index :downloads, ["contribution_id"]

  end

  def self.down

    remove_index :viewings, ["contribution_id"]
#   remove_index :downloads, ["contribution_id"]

  end
end
