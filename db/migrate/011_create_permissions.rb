class CreatePermissions < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      t.column :contributor_id, :integer
      t.column :contributor_type, :string
      
      t.column :policy_id, :integer
      
      t.column :download, :boolean, :default => false
      t.column :edit, :boolean, :default => false
      t.column :view, :boolean, :default => false
    end
  end

  def self.down
    drop_table :permissions
  end
end
