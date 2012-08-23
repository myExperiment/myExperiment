# myExperiment: db/migrate/097_add_events.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class AddEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|

      t.string  :subject_type
      t.integer :subject_id
      t.string  :subject_label

      t.string  :action

      t.string  :objekt_type
      t.integer :objekt_id
      t.string  :objekt_label

      t.string  :extra

      t.datetime :created_at
    end
  end

  def self.down
    drop_table :events
  end
end
