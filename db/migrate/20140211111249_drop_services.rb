class DropServices < ActiveRecord::Migration
  def self.up
    drop_table :service_categories
    drop_table :service_deployments
    drop_table :service_providers
    drop_table :service_tags
    drop_table :service_types
    drop_table :services
  end

  def self.down
  end
end
