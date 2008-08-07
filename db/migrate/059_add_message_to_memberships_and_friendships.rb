class AddMessageToMembershipsAndFriendships < ActiveRecord::Migration
  def self.up
    add_column :memberships, :message, :string, :limit => 500, :default => nil 
    add_column :friendships, :message, :string, :limit => 500, :default => nil
  end

  def self.down
    remove_column :memberships, :message
    remove_column :friendships, :message
  end
end
