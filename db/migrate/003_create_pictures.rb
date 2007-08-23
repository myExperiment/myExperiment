class CreatePictures < ActiveRecord::Migration
  def self.up
    create_table :pictures do |t|
      t.column :data, :binary
      t.column :user_id, :integer
    end
    
    execute "ALTER TABLE `pictures` MODIFY `data` MEDIUMBLOB"
  end

  def self.down
    drop_table :pictures
  end
end
