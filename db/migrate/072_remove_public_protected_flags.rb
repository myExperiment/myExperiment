class RemovePublicProtectedFlags < ActiveRecord::Migration
  def self.up
#   remove_column :policies, :download_public
#   remove_column :policies, :edit_public
#   remove_column :policies, :view_public
#   remove_column :policies, :download_protected
#   remove_column :policies, :edit_protected
#   remove_column :policies, :view_protected
  end

  def self.down
#   add_column :policies, :download_public,    :boolean, :default => true
#   add_column :policies, :edit_public,        :boolean, :default => false
#   add_column :policies, :view_public,        :boolean, :default => true
#   add_column :policies, :download_protected, :boolean, :default => false
#   add_column :policies, :edit_protected,     :boolean, :default => false
#   add_column :policies, :view_protected,     :boolean, :default => false
  end
end
