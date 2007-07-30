class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.column :open_id, :string, :null => false
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :users
  end
end
