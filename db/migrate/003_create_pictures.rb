# myExperiment: db/migrate/003_create_pictures.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreatePictures < ActiveRecord::Migration
  def self.up
    create_table :pictures do |t|
      #t.column :data, :string
      t.column :data, :binary
      t.column :user_id, :integer
    end
    
    execute "ALTER TABLE `pictures` MODIFY `data` MEDIUMBLOB"
  end

  def self.down
    drop_table :pictures
  end
end
