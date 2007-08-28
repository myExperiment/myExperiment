class CreateLists < ActiveRecord::Migration
  def self.up

  create_table :lists, :force => true do |t|
    t.column :user_id, :integer, :default => 0, :null => false
    t.column :title, :string, :limit => 50, :default => ""
    t.column :created_at, :datetime, :null => false
  end

  end

  def self.down
    drop_table :lists
  end
end
