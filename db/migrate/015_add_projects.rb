class AddProjects < ActiveRecord::Migration

  def self.up
    create_table :projects, :force => true do |t|
      t.column :title, :string, :default => ""
      t.column :unique, :string, :limit => 50
      t.column :created_at, :datetime, :null => false
      t.column :modified_at, :datetime
      t.column :user_id, :integer, :default => 0, :null => false
    end

    add_index :projects, ["user_id"], :name => "fk_projects_user"

    create_table :memberships, :force => true do |t|
      t.column :project_id, :integer, :default => 0, :null => false
      t.column :user_id, :integer, :default => 0, :null => false
    end

    add_index :memberships, ["project_id"], :name => "fk_memberships_project"
    add_index :memberships, ["user_id"], :name => "fk_memberships_user"
  end

  def self.down
    drop_table :projects
    drop_table :memberships
  end

end
