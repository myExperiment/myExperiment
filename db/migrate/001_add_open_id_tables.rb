class AddOpenIdTables < ActiveRecord::Migration
 def self.up
  create_table :users do |table|
     table.column :openid_url, :string
     table.column :avatar, :integer, :null => true
     table.column :updated_at, :datetime
     table.column :created_at, :datetime
  end
 end

 def self.down
  drop_table :users
 end
end
