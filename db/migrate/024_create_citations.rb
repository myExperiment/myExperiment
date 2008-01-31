class CreateCitations < ActiveRecord::Migration
  def self.up
    create_table :citations do |t|
      t.column :user_id, :integer
      t.column :workflow_id, :integer
      t.column :workflow_version, :integer
      t.column :authors, :text
      t.column :title, :string
      t.column :publication, :string
      t.column :published_at, :datetime
      t.column :accessed_at, :datetime
      t.column :url, :string
      t.column :isbn, :string
      t.column :issn, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :citations
  end
end
