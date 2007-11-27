class ModifyProfiles < ActiveRecord::Migration
  def self.up
    add_column :profiles, :field_or_industry, :string
    add_column :profiles, :occupation_or_roles, :string
    add_column :profiles, :organisations, :string
    add_column :profiles, :location_city, :string
    add_column :profiles, :location_country, :string
    add_column :profiles, :interests, :text
    add_column :profiles, :contact_details, :text
    
  end

  def self.down
    remove_column :profiles, :field_or_industry
    remove_column :profiles, :occupation_or_roles
    remove_column :profiles, :organisations
    remove_column :profiles, :location_city
    remove_column :profiles, :location_country
    remove_column :profiles, :interests
    remove_column :profiles, :contact_details
  end
end
