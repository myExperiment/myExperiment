class CreateChannelmessages < ActiveRecord::Migration
  def self.up
    create_table :channelmessages, :options => "auto_increment = 1" do |t|
      t.column "created_at", :datetime
      t.column "topic_id", :integer
      t.column "content", :text
      t.column "channel_id", :integer
      t.column "sender_id", :integer
      t.column "level", :string
      t.column "recepient_id", :integer
    end
  end

  def self.down
    drop_table :channelmessages
  end
end
