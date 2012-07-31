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
      
      t.column :version, :integer
      t.column :preview_id, :integer

      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      
      t.column :license, :string, 
               :limit => 10, :null => false, 
               :default => "by-sa"
    end
    
    create_table :workflow_versions do |t|
      t.column "workflow_id",       :integer
      t.column "version",           :integer
      t.column "contributor_id",    :integer
      t.column "contributor_type",  :string
      t.column "title",             :string
      t.column "unique_name",       :string
      t.column "scufl",             :text
      t.column "body",              :text
      t.column "body_html",         :text
      t.column "created_at",        :datetime
      t.column "updated_at",        :datetime
      t.column "license",           :string
      t.column "preview_id",        :integer
    end

    add_index :workflow_versions, [ :workflow_id ]
  end

  def self.down
    drop_table :workflows
    drop_table :workflow_versions
  end
end
