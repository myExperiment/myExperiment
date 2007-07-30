class CreateRelationships < ActiveRecord::Migration
  def self.up
    create_table :relationships do |t|
      t.column :network_id, :integer
      t.column :relation_id, :integer
      t.column :created_at, :datetime
      t.column :accepted_at, :datetime
    end
  end

  def self.down
    drop_table :relationships
  end
end
