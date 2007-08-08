class CreateBlobs < ActiveRecord::Migration
  def self.up
    create_table :blobs do |t|
      t.column :contributor_id, :integer
      t.column :contributor_type, :string
      t.column :local_name, :string
      t.column :content_type, :string
      t.column :data, :binary
    end
  end

  def self.down
    drop_table :blobs
  end
end
