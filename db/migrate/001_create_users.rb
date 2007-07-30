class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.column :openid_url, :string
      t.column :name, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :users
  end
end
