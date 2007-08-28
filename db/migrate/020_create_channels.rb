class CreateChannels < ActiveRecord::Migration
  
  def self.up
    create_table :channels  do |t|
      t.column "name", :string
      t.column "title", :string
      t.column "private", :integer, :default => 0
      t.column "topic_id", :integer, :default => 0, :null => false
    end
  end

  def self.down
    drop_table :channels
  end
end
