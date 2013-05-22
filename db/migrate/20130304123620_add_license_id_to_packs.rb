class AddLicenseIdToPacks < ActiveRecord::Migration
  def self.up#
    add_column :packs, :license_id, :integer
  end

  def self.down
    remove_column :packs, :license_id
  end
end
