# myExperiment: db/migrate/076_create_algorithm_instances.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateAlgorithmInstances < ActiveRecord::Migration
  def self.up
    create_table :algorithm_instances do |t|
      t.column :algorithm_id, :integer
      t.column :app_id, :integer
    end
  end

  def self.down
    drop_table :algorithm_instances
  end
end

