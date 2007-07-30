class CreateNetworks < ActiveRecord::Migration
  def self.up
    create_table :networks do |t|
      t.column :user_id, :integer
      t.column :title, :string
      t.column :unique, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :networks
  end
end
