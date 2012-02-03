class CreateViewings < ActiveRecord::Migration
  def self.up
    create_table :viewings do |t|
      t.column :contribution_id, :integer
      t.column :user_id, :integer
      t.column :created_at, :datetime
    end
    
#   add_column :contributions, :viewings_count, :integer, :default => 0
    add_column :users, :viewings_count, :integer, :default => 0
  end

  def self.down
    drop_table :viewings
    
#   remove_column :contributions, :viewings_count
    remove_column :users, :viewings_count
  end
end
