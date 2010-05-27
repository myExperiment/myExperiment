class AddIndexToProfilesTable < ActiveRecord::Migration
  def self.up

    add_index :profiles, ["user_id"], :name => "index_profiles_on_user_id"

  end

  def self.down

    remove_index :profiles, :name => "index_profiles_on_user_id"

  end
end
