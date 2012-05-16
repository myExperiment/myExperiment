# myExperiment: db/migrate/20120508145518_create_research_objects.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateResearchObjects < ActiveRecord::Migration
  def self.up
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

  def self.down
    drop_table :research_objects
  end
end
