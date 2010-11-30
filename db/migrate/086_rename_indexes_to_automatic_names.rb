# myExperiment: db/migrate/086_rename_indexes_to_automatic_names.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

class RenameIndexesToAutomaticNames < ActiveRecord::Migration
  def self.up
    remove_index "bookmarks",         :name => "fk_bookmarks_user"
    remove_index "comments",          :name => "fk_comments_user"
    remove_index "contributions",     :name => "contributions_contributable_index"
    remove_index "contributions",     :name => "contributions_contributor_index"
    remove_index "friendships",       :name => "friendships_friend_id_index"
    remove_index "friendships",       :name => "friendships_user_id_index"
    remove_index "memberships",       :name => "memberships_network_id_index"
    remove_index "memberships",       :name => "memberships_user_id_index"
    remove_index "networks",          :name => "networks_used_id_index"
    remove_index "permissions",       :name => "permissions_policy_id_index"
    remove_index "ratings",           :name => "fk_ratings_user"
    remove_index "reviews",           :name => "fk_reviews_user"
    remove_index "workflow_versions", :name => "workflow_versions_workflow_id_index"

    add_index "bookmarks",         ["user_id"]
    add_index "comments",          ["user_id"]
    add_index "contributions",     ["contributable_id", "contributable_type"]
    add_index "contributions",     ["contributor_id", "contributor_type"]
    add_index "friendships",       ["friend_id"]
    add_index "friendships",       ["user_id"]
    add_index "memberships",       ["network_id"]
    add_index "memberships",       ["user_id"]
    add_index "networks",          ["user_id"]
    add_index "permissions",       ["policy_id"]
    add_index "ratings",           ["user_id"]
    add_index "reviews",           ["user_id"]
    add_index "workflow_versions", ["workflow_id"]
  end

  def self.down

  end
end
