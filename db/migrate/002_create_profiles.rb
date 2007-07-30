class CreateProfiles < ActiveRecord::Migration
  def self.up
    create_table :profiles do |t|
      t.column :user_id, :integer
      t.column :avatar_id, :integer
      t.column :name, :string
      t.column :email, :string
      t.column :website, :string
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :profiles
  end
end
