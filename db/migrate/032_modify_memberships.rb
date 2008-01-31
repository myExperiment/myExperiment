
class ModifyMemberships < ActiveRecord::Migration
  def self.up
    rename_column :memberships, :accepted_at, :user_established_at
    add_column :memberships, :network_established_at, :datetime
    add_column :networks, :auto_accept, :boolean, :default => false

    execute 'UPDATE memberships SET network_established_at = user_established_at'
  end

  def self.down
    rename_column :memberships, :user_established_at, :accepted_at
    remove_column :memberships, :network_established_at
    remove_column :networks, :auto_accept
  end
end
