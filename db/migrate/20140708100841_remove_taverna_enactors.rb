class RemoveTavernaEnactors < ActiveRecord::Migration
  def self.up
    drop_table :taverna_enactors
  end

  def self.down
  end
end
