# myExperiment: db/migrate/db/migrate/082_create_curation_events.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateCurationEvents < ActiveRecord::Migration
  def self.up
    create_table :curation_events do |t|
      t.column :user_id,      :integer
      t.column :category,     :string
      t.column :object_type,  :string
      t.column :object_id,    :integer
      t.column :details,      :text
      t.column :details_html, :text
      t.column :created_at,   :datetime
      t.column :updated_at,   :datetime
    end
  end

  def self.down
    drop_table :curation_events
  end
end
