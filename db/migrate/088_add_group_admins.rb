
class AddGroupAdmins < ActiveRecord::Migration
  def self.up
    add_column :memberships, :administrator, :boolean, :default => false
  end

  def self.down
    remove_column :memberships, :administrator
  end
end
