class AddWorkflowsSupport < ActiveRecord::Migration
 def self.up
   create_table :workflows do |table|
    table.column "scufl",       :text
    table.column "image",       :text
    table.column "title",       :text
    table.column "description", :text
    table.column "user_id", :integer
    table.column :created_at, :datetime
   end
 end

 def self.down
   drop_table :workflows
 end
end
