class CreateLicenses < ActiveRecord::Migration
  def self.up
    create_table :licenses do |t|
      t.column :user_id, :integer
      t.column :unique_name, :string
      t.column :title, :string
      t.column :description, :text
      t.column :description_html, :text
      t.column :url, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
 end

 def self.down
    drop_table :licenses
  end
end
