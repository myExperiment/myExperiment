class RemoveInvitedByFromNetworks < ActiveRecord::Migration
  def self.up
    remove_column :networks, :inviter_id
  end

  def self.down
    add_column :networks, :inviter_id, :integer
  end
end
