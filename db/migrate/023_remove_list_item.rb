class RemoveListItem < ActiveRecord::Migration
  def self.up
    drop_table :list_items
  end

  def self.down

  create_table :list_items, :force => true do |t|
    t.column :body, :text, :default => "", :null => false
    t.column :created_at, :datetime, :null => false
  end

  end
end
