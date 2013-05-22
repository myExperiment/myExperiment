# myExperiment: db/migrate/001_create_users.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

class RemoveSimplePages < ActiveRecord::Migration

  def self.up
    drop_table :simple_page_versions
    drop_table :simple_pages
  end

  def self.down
    create_table "simple_page_versions", :force => true do |t|
      t.column "simple_page_id", :integer
      t.column "version",        :integer
      t.column "filename",       :string
      t.column "title",          :string
      t.column "content",        :text
      t.column "created_at",     :datetime
      t.column "updated_at",     :datetime
    end

    create_table "simple_pages", :force => true do |t|
      t.column "filename",   :string
      t.column "title",      :string
      t.column "content",    :text
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      t.column "version",    :integer
    end
  end
end
