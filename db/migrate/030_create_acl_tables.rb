class CreateAclTables < ActiveRecord::Migration
  def self.up
    create_table :sharing_users do |t|
      t.column :workflow_id, :integer
      t.column :user_id, :integer
    end
    
    create_table :sharing_projects do |t|
      t.column :workflow_id, :integer
      t.column :project_id, :integer
    end
    
    # Access Control Layer (4 bits)
    # MSB all? friends? sharing_users? sharing_projects? LSB
    
    # 0 - owner only (owner for 1-8 incl.)
    # 1 - projects
    # 2 - users
    # 3 - users and projects
    # 4 - friends
    # 5 - friends and projects
    # 6 - friends and users
    # 7 - friends, users and projects
    # 8 - ALL
  
    add_column :workflows, :acl_r, :integer, :default => 8
    add_column :workflows, :acl_m, :integer, :default => 0
    add_column :workflows, :acl_d, :integer, :default => 0
  end

  def self.down
    drop_table :sharing_users
    drop_table :sharing_projects
    
    remove_column :workflows, :acl_r
    remove_column :workflows, :acl_m
    remove_column :workflows, :acl_d
  end
end
