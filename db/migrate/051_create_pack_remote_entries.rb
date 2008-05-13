class CreatePackRemoteEntries < ActiveRecord::Migration
  def self.up
    create_table :pack_remote_entries do |t|
      t.column :pack_id, :integer, :null => false
      
      t.column :title, :string, :null => false
      
      t.column :uri, :string, :null => false
      t.column :alternate_uri, :string
      
      t.column :comment, :text
      
      t.column :user_id, :integer, :null => false
      
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :pack_remote_entries
  end
end
