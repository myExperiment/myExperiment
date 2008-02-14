class CreateTavernaEnactors < ActiveRecord::Migration
  def self.up
    create_table :taverna_enactors do |t|
      t.column :title, :string
      
      t.column :description, :text
      
      t.column :contributor_id, :integer
      t.column :contributor_type, :string
      
      t.column :url, :string
      t.column :username, :string
      t.column :crypted_password, :string
      
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :taverna_enactors
  end
end
