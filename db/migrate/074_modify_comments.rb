class ModifyComments < ActiveRecord::Migration
  def self.up
    remove_column :comments, :title
  end

  def self.down
    add_column :comments, :title, :string, :limit => 50, :default => ""
  end
end
