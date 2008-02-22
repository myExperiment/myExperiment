class CreateExperiments < ActiveRecord::Migration
  def self.up
    create_table :experiments do |t|
      t.column :title, :string
      
      t.column :description, :text
      t.column :description_html, :text
      
      t.column :contributor_id, :integer
      t.column :contributor_type, :string
      
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :experiments
  end
end
