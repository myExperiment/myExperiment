# myExperiment: db/migrate/20130423091433_create_atom_feed_tables.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

class CreateAtomFeedTables < ActiveRecord::Migration
  def self.up

    create_table :feeds do |t|

      t.string  :title
      t.text    :uri
      t.string  :context_type
      t.integer :context_id
      t.string  :username 
      t.string  :password

      t.timestamps
    end

    create_table :feed_items do |t|

      t.integer  :feed_id
      t.string   :identifier
      t.string   :title
      t.text     :content
      t.string   :author
      t.string   :link
      t.datetime :item_published_at
      t.datetime :item_updated_at
      t.text     :data

      t.timestamps
    end
  end

  def self.down
    drop_table :feed_items
    drop_table :feeds
  end
end
