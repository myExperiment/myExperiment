class CreateDeprecationEvents < ActiveRecord::Migration
  def self.up
    create_table :deprecation_events do |t|
      t.string :title
      t.datetime :date
      t.text :details
    end
  end

  def self.down
    drop_table :deprecation_events
  end
end
