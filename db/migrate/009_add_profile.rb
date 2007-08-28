class AddProfile < ActiveRecord::Migration

  def self.up
    create_table :profiles do |table|
      table.column :unique, :string
      table.column :name, :string
      table.column :email, :string
      table.column :website, :string
      table.column :profile, :text
      table.column :user_id, :integer, :default => 0, :null => false
      table.column :updated_at, :datetime
      table.column :created_at, :datetime
    end

    add_index :profiles, ["user_id"], :name => "fk_profiles_user"

  end

  def self.down
    drop_table :profiles
  end

end
