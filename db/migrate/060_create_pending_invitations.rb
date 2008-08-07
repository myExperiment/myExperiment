class CreatePendingInvitations < ActiveRecord::Migration
  
  # Table for inviting new users (that don't have account yet) directly into the groups /
  # or for making friendship requests. This table will be queried right after registration
  # is complete - to check if there are any friendship / membership requests for the new user.
  #
  # Fields: 
  # 'email'        :: of the person who is being invited
  # 'created_at '  :: date, when the request was made (useful if we decide to remove requests that are >30 days old)
  # 'request_type' :: "membership" OR "friendship"
  # 'requested_by' :: id of the user, who has sent the request (i.e that could be not necessarily a group's
  #                   admin, but other person, who has rights to manage the group - which is planned to be
  #                   implemented at some point)
  # 'request_for'  :: id of the user who wants to establish friendship with the new user (same with 'requested_by'
  #                   in this case) or id of the group which is to be joined
  # 'message'      :: an invitation message that would normally be located in 'memberships' / 'friendships' tables,
  #                   but should be stored here because the new user won't have the ID yet.
  
  def self.up
    create_table :pending_invitations do |t|
      t.column :email, :string
      t.column :created_at, :datetime
      
      t.column :request_type, :string
      t.column :requested_by, :integer
      t.column :request_for, :integer
      
      t.column :message, :string, :limit => 500
    end
  end

  def self.down
    drop_table :pending_invitations
  end
end
