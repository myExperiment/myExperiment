class CreateChannelTopics < ActiveRecord::Migration
  def self.up
    create_table :channel_topics do |t|
      t.column "title", :string
      t.column "channel_id", :integer, :default => 0
    end
  end

  def self.down
    drop_table :channel_topics
  end
end
