class CreateCachedHistories < ActiveRecord::Migration
  def self.up
    create_table :cached_histories do |t|
      t.column :action, :string
      t.column :controller, :string
      t.column :updated_at, :datetime
      t.column :result, :text
    end
    
    add_index :cached_histories, [ :action, :controller ]
  end

  def self.down
    drop_table :cached_histories
  end
end
