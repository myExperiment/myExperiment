class AddIndexesToFrequentlyUsedTables < ActiveRecord::Migration
  def self.up

    add_index :permissions, ["policy_id"], :name => "permissions_policy_id_index"

    add_index :workflow_versions, ["workflow_id"], :name => "workflow_versions_workflow_id_index"

    add_index :contributions, ["contributable_id", "contributable_type"], :name => "contributions_contributable_index"
    add_index :contributions, ["contributor_id",   "contributor_type"],   :name => "contributions_contributor_index"

    add_index :memberships, ["user_id"],    :name => "memberships_user_id_index"
    add_index :memberships, ["network_id"], :name => "memberships_network_id_index"

    add_index :networks, ["user_id"], :name => "networks_used_id_index"

    add_index :friendships, ["user_id"], :name => "friendships_user_id_index"

    add_index :friendships, ["friend_id"], :name => "friendships_friend_id_index"

  end

  def self.down

    remove_index :permissions, :name => "permissions_policy_id_index"

    remove_index :workflow_versions, :name => "workflow_versions_workflow_id_index"

    remove_index :contributions, :name => "contributions_contributable_index"
    remove_index :contributions, :name => "contributions_contributor_index"

    remove_index :memberships, :name => "memberships_user_id_index"
    remove_index :memberships, :name => "memberships_network_id_index"

    remove_index :networks, :name => "networks_used_id_index"

    remove_index :friendships, :name => "friendships_user_id_index"

    remove_index :friendships, :name => "friendships_friend_id_index"

  end
end
