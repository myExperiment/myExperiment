class AddTokenToPendingInvitations < ActiveRecord::Migration
  # this migration is intended to make it possible for new users to register
  # with a different email address than one that was used for invitations,
  # still being able to get all the invitations upon successful registration
  
  def self.up
    add_column :pending_invitations, :token, :string, :default => nil
  end

  def self.down
    remove_column :pending_invitations, :token
  end
end
