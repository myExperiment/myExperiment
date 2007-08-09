class CreatePolicies < ActiveRecord::Migration
  def self.up
    create_table :policies do |t|
      t.column :contributor_id, :integer
      t.column :contributor_type, :string
      
      t.column :name, :string
      
      t.column :download_public, :boolean, :default => true
      t.column :edit_public, :boolean, :default => true
      t.column :view_public, :boolean, :default => true
      
      t.column :download_protected, :boolean, :default => true
      t.column :edit_protected, :boolean, :default => true
      t.column :view_protected, :boolean, :default => true
      
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :policies
  end
end
