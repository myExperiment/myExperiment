class RenamePasswordToEncryptedPasswordInFeeds < ActiveRecord::Migration
  def change
    rename_column :feeds, :password, :encrypted_password
  end
end
