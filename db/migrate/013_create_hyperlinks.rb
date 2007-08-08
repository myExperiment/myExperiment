class CreateHyperlinks < ActiveRecord::Migration
  def self.up
    create_table :hyperlinks do |t|
      t.column :contributor_id, :integer
      t.column :contributor_type, :string
      
      t.column :path, :string
    end
  end

  def self.down
    drop_table :hyperlinks
  end
end
