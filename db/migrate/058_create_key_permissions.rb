class CreateKeyPermissions < ActiveRecord::Migration
  def self.up
    create_table :key_permissions do |t|
      t.column :client_application_id, :integer
      t.column :for, :string
    end
  end

  def self.down
    drop_table :key_permissions
  end
end
