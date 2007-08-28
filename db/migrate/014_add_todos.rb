class AddTodos < ActiveRecord::Migration
  def self.up
    create_table :todos, :force => true do |t|
      t.column "subject", :string
      t.column "created_at",  :datetime
      t.column "list_id", :integer
    end

    create_table :lists, :force => true do |t|
      t.column "title", :string
      t.column "created_at", :datetime
    end

  end

  def self.down
    drop_table :todos
    drop_table :lists
  end
end
