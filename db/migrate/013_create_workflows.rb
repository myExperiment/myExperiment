# myExperiment: db/migrate/013_create_workflows.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateWorkflows < ActiveRecord::Migration
  def self.up
    create_table :workflows do |t|
      t.column :contributor_id, :integer
      t.column :contributor_type, :string
      
      t.column :scufl, :binary
      t.column :image, :string
      t.column :svg, :string
      
      t.column :title, :string
      t.column :unique_name, :string
      
      t.column :body, :text
      t.column :body_html, :text
      
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      
      t.column :license, :string, 
               :limit => 10, :null => false, 
               :default => "by-sa"
    end
    
    Workflow.create_versioned_table
  end

  def self.down
    drop_table :workflows
    
    Workflow.drop_versioned_table
  end
end
