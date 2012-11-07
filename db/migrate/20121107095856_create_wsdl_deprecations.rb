class CreateWsdlDeprecations < ActiveRecord::Migration
  def self.up
    create_table :wsdl_deprecations do |t|
      t.string :wsdl
      t.datetime :deprecated_at
      t.text :details
      t.timestamps
    end
  end

  def self.down
    drop_table :wsdl_deprecations
  end
end
