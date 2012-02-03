class AddInvitedByToMemberships < ActiveRecord::Migration
  def self.up
    add_column :networks, :inviter_id, :integer
  end

  def self.down
    remove_column :networks, :inviter_id
  end
end
