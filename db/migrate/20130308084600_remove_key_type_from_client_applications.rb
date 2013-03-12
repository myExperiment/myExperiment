class RemoveKeyTypeFromClientApplications < ActiveRecord::Migration
  def self.up
    remove_column :client_applications, :key_type
  end

  def self.down
    add_column :client_applications, :key_type, :string
  end
end
