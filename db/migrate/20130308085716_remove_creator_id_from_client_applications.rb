class RemoveCreatorIdFromClientApplications < ActiveRecord::Migration
  def self.up
    remove_column :client_applications, :creator_id
  end

  def self.down
    add_column :client_applications, :creator_id, :integer
  end
end
