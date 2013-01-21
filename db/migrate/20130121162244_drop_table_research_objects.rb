# myExperiment: db/migrate/20130121162244_drop_table_research_objects.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.
class DropTableResearchObjects < ActiveRecord::Migration
  def self.up
    drop_table :research_objects
    Contribution.destroy_all(:contributable_type => "ResearchObject")
  end

  def self.down
    create_table "research_objects", :force => true do |t|
      t.string   "title"
      t.text     "description"
      t.text     "description_html"
      t.text     "url"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "content_blob_id"
      t.integer  "contributor_id"
      t.string   "contributor_type"
    end
  end
end
