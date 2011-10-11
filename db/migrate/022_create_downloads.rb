class CreateDownloads < ActiveRecord::Migration
  def self.up
#   create_table :downloads do |t|
#     t.column :contribution_id, :integer
#     t.column :user_id, :integer
#     t.column :created_at, :datetime
#   end
    
#   add_column :contributions, :downloads_count, :integer, :default => 0
    add_column :users, :downloads_count, :integer, :default => 0
  end

  def self.down
#   drop_table :downloads
    
#   remove_column :contributions, :downloads_count
#   remove_column :users, :downloads_count
  end
end
