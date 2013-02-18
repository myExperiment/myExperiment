class CreateWorkflowPorts < ActiveRecord::Migration
  def self.up
    create_table :workflow_ports do |t|
      t.string :name
      t.string :port_type
      t.integer :workflow_id
    end
  end

  def self.down
    drop_table :workflow_ports
  end
end
