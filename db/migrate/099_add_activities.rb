# myExperiment: db/migrate/097_add_activities.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

class AddActivities < ActiveRecord::Migration
  def self.up
    create_table :activities do |t|

      t.string   :subject_type
      t.integer  :subject_id
      t.string   :subject_label

      t.string   :action

      t.string   :objekt_type
      t.integer  :objekt_id
      t.string   :objekt_label

      t.string   :context_type
      t.integer  :context_id

      t.string   :auth_type
      t.integer  :auth_id

      t.string   :extra
      t.string   :uuid
      t.integer  :priority, :default => 0

      t.boolean  :featured, :default => false
      t.boolean  :hidden,   :default => false

      t.datetime :timestamp
    end

    create_table :subscriptions do |t|
      t.integer :user_id
      t.string  :objekt_type
      t.integer :objekt_id
    end
  end

  def self.down
    drop_table :subscriptions
    drop_table :activities
  end
end
