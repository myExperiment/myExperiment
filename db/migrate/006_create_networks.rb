class CreateNetworks < ActiveRecord::Migration
  def self.up
    create_table :networks do |t|
    end
  end

  def self.down
    drop_table :networks
  end
end
