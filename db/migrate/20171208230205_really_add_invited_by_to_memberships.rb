class ReallyAddInvitedByToMemberships < ActiveRecord::Migration
  def up
    add_column :memberships, :inviter_id, :integer
  end

  def down
    remove_column :memberships, :inviter_id
  end
end
