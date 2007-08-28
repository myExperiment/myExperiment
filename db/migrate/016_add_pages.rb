class AddPages < ActiveRecord::Migration

  def self.up
    create_table :pages, :force => true do |t|
      t.column :namespace, :string, :default => ""
      t.column :name, :string, :default => ""
      t.column :content, :text
      t.column :created_at, :datetime, :null => false
      t.column :modified_at, :datetime
      t.column :pageable_type, :string, :default => "", :null => false
      t.column :pageable_id, :integer, :default => 0, :null => false
      t.column :user_id, :integer, :default => 0, :null => false
    end

    add_index :pages, ["user_id"], :name => "fk_pages_user"
  end

  def self.down
    drop_table :pages
  end
  
end
