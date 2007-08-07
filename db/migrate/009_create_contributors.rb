class CreateContributors < ActiveRecord::Migration
  def self.up
    create_table :contributions do |t|
      t.column :contributor_id, :integer
      t.column :contributor_type, :string
      t.column :contributable_id, :integer
      t.column :contributable_type, :string
      t.column :policy_id, :integer
      t.column :created_at, :datetime
    end
    
    create_table :policies do |t|
      t.column :contributor_id, :integer
      t.column :contributor_type, :string
      
      t.column :download_public, :boolean, :default => true
      t.column :edit_public, :boolean, :default => true
      t.column :view_public, :boolean, :default => true
      
      t.column :download_protected, :boolean, :default => true
      t.column :edit_protected, :boolean, :default => true
      t.column :view_protected, :boolean, :default => true
    end
    
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
    drop_table :contributions
    drop_table :policies
    drop_table :permissions
  end
end
