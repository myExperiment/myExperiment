class CreatePictures < ActiveRecord::Migration
  def self.up
    create_table :pictures do |t|
      t.column :user_id, :integer
      t.column :data, :binary
    end
    
    execute "ALTER TABLE `pictures` MODIFY `data` MEDIUMBLOB"
  end

  def self.down
    drop_table :pictures
  end
end
