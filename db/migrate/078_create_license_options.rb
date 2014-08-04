class CreateLicenseOptions < ActiveRecord::Migration
  def self.up
    create_table :license_options do |t|
      t.column :user_id, :integer
      t.column :title, :string
      t.column :description, :text
      t.column :description_html, :text
      t.column :uri, :string
      t.column :predicate, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :license_options
  end
end
