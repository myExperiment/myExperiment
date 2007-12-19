class UpdateUserAccounts < ActiveRecord::Migration
  def self.up
    add_column :users, :email, :string
    add_column :users, :unconfirmed_email, :string
    add_column :users, :email_confirmed_at, :datetime, :default => nil
    add_column :users, :activated_at, :datetime, :default => nil
    # Activate accounts of all existing users
    execute 'UPDATE users SET activated_at = created_at'
    add_column :users, :receive_notifications, :boolean, :default => true
    
    add_column :users, :reset_password_code, :string
    add_column :users, :reset_password_code_until, :datetime
  end

  def self.down
    remove_column :users, :email
    remove_column :users, :unconfirmed_email
    remove_column :users, :email_confirmed_at
    remove_column :users, :activated_at
    remove_column :users, :receive_notifications
    
    remove_column :users, :reset_password_code
    remove_column :users, :reset_password_code_until
  end
end
