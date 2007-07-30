class CreateMemberships < ActiveRecord::Migration
  def self.up
    create_table :memberships do |t|
      t.column :user_id, :integer
      t.column :network_id, :integer
      t.column :created_at, :datetime
      t.column :accepted_at, :datetime
      t.column :destroyed_at, :datetime
    end
  end

  def self.down
    drop_table :memberships
  end
end
