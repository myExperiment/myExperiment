class RemoveNetworkRelationships < ActiveRecord::Migration
  def self.up
    drop_table :relationships
  end

  def self.down
    create_table "relationships", :force => true do |t|
      t.column "network_id",  :integer
      t.column "relation_id", :integer
      t.column "created_at",  :datetime
      t.column "accepted_at", :datetime
    end
  end
end


