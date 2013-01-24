class RemoveBlogs < ActiveRecord::Migration
  def self.up
    drop_table :blogs
  end

  def self.down
    create_table :blogs do |t|
      t.column :contributor_id, :integer
      t.column :contributor_type, :string
      t.column :title, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end
end
