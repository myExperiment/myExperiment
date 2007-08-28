class CreateListItems < ActiveRecord::Migration
  def self.up

  create_table :list_items, :force => true do |t|
    t.column :body, :text, :default => "", :null => false
    t.column :created_at, :datetime, :null => false
  end

  end

  def self.down
    drop_table :list_items
  end
end
