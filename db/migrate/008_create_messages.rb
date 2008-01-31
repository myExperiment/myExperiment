# myExperiment: db/migrate/008_create_messages.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.column :from, :integer
      t.column :to, :integer
      t.column :subject, :string
      t.column :body, :text
      t.column :reply_id, :integer
      t.column :created_at, :datetime
      t.column :read_at, :datetime
      t.column :body_html, :text
    end
  end

  def self.down
    drop_table :messages
  end
end
