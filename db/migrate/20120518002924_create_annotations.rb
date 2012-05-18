# myExperiment: db/migrate/20120518002924_create_annotations.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateAnnotations < ActiveRecord::Migration
  def self.up
    create_table "annotations", :force => true do |t|
      t.integer  "research_object_id"
      t.string   "subject_text"
      t.string   "predicate_text"
      t.string   "objekt_text"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end

  def self.down
    drop_table :announcements
  end
end
