class RestfulAuthenticationForUser < ActiveRecord::Migration
  def self.up
#    add_column :users, :email, :string
    add_column :users, :crypted_password, :string
    add_column :users, :salt, :string
#    add_column :users, :created_at, :datetime
#    add_column :users, :updated_at, :datetime
    add_column :users, :remember_token, :string
    add_column :users, :remember_token_expires_at, :datetime
    add_column :users, :activation_code, :string
    add_column :users, :activated_at, :datetime
  end

  def self.down
#    remove_column :users, :email
    remove_column :users, :crypted_password
    remove_column :users, :salt
#    remove_column :users, :created_at
#    remove_column :users, :updated_at
    remove_column :users, :remember_token
    remove_column :users, :remember_token_expires_at
    remove_column :users, :activation_code
    remove_column :users, :activated_at
  end
end

