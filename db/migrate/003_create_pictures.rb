class CreatePictures < ActiveRecord::Migration
  def self.up
    create_table :pictures do |t|
      t.column :user_id, :integer, :null => false
      t.column :data, :binary, :size => 10_000_000, :null => false
    end
    
    execute "ALTER TABLE `pictures` MODIFY `data` MEDIUMBLOB"
  end

  def self.down
    drop_table :pictures
  end
end
