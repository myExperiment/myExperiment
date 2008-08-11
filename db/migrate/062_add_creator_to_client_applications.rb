class AddCreatorToClientApplications < ActiveRecord::Migration
  # this migration is designed to allow client applications to have creator uids
  # so that admins can create system keys that users can authorize
  
  def self.up
    add_column :client_applications,:creator_id, :integer, :default => nil
  end

  def self.down
    remove_column :client_applications, :creator_id
  end
end
