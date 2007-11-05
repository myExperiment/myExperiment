
class ModifyPermissions < ActiveRecord::Migration
  def self.up
    add_column :permissions, :share_mode, :integer
    add_column :permissions, :update_mode, :integer
  end

  def self.down
    remove_column :permissions, :share_mode
    remove_column :permissions, :update_mode
  end
end
