class DeleteServiceContributions < ActiveRecord::Migration
  def self.up
    Contribution.delete_all("contributable_type = 'Service'")
  end

  def self.down
  end
end
