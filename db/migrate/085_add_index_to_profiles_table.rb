class AddIndexToProfilesTable < ActiveRecord::Migration
  def self.up

    add_index :profiles, ["user_id"]

  end

  def self.down

    remove_index :profiles, ["user_id"]

  end
end
