# myExperiment: db/migrate/20120518002924_create_statements.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateStatements < ActiveRecord::Migration
  def self.up
    create_table "statements", :force => true do |t|
      t.integer  "research_object_id"
      t.string   "resource"
      t.integer  "version"
      t.text     "context_uri"
      t.string   "subject_text"
      t.string   "predicate_text"
      t.string   "objekt_text"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end

  def self.down
    drop_table :statements
  end
end
