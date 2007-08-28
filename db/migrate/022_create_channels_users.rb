class CreateChannelsUsers < ActiveRecord::Migration
  def self.up
    create_table(:channels_users, :primary_key => "cu_id") do |t|
      t.column "channel_id", :integer, :default => 0
      t.column "user_id", :integer, :default => 0
      t.column "last_seen", :datetime
    end
  end

  def self.down
     drop_table :channels_users
  end
end
