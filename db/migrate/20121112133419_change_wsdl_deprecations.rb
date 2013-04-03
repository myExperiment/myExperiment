class ChangeWsdlDeprecations < ActiveRecord::Migration
  def self.up
    add_column :wsdl_deprecations, :deprecation_event_id, :integer
    remove_column :wsdl_deprecations, :details
    remove_column :wsdl_deprecations, :deprecated_at
    remove_column :wsdl_deprecations, :created_at
    remove_column :wsdl_deprecations, :updated_at
  end

  def self.down
    remove_column :wsdl_deprecations, :deprecation_event_id
    add_column :wsdl_deprecations, :details, :text
    add_column :wsdl_deprecations, :deprecated_at, :datetime
    add_column :wsdl_deprecations, :created_at, :datetime
    add_column :wsdl_deprecations, :updated_at, :datetime
  end
end
