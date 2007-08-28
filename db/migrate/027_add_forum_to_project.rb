class AddForumToProject < ActiveRecord::Migration
  def self.up
    add_column :projects, :forum_id, :integer
    
    add_index :projects, ["forum_id"], :name => "fk_projects_forum"
  end
  
  def self.down
    remove_column :projects, :forum_id
  end
end