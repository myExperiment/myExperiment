class CreateLicenseAttributes < ActiveRecord::Migration
  def self.up
    create_table :license_attributes do |t|
      t.column :license_id, :integer
      t.column :license_option_id, :integer
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :license_attributes
  end
end
