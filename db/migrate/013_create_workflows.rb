class CreateWorkflows < ActiveRecord::Migration
  def self.up
    create_table :workflows do |t|
      t.column :contributor_id, :integer
      t.column :contributor_type, :string
      
      t.column :scufl, :binary
      t.column :image, :string
      
      t.column :title, :string
      t.column :unique, :string
      t.column :description, :text
      
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
    
    Workflow.create_versioned_table
  end

  def self.down
    drop_table :workflows
    
    Workflow.drop_versioned_table
  end
end
