class CreatePictures < ActiveRecord::Migration
  def self.up
    create_table :pictures do |t|
      t.column "data", :binary, :size => 10_000_000, :null => false
      t.column "user_id", :integer
    end

    add_index :pictures, ["user_id"], :name => "fk_pictures_user"

    execute "ALTER TABLE `pictures` MODIFY `data` MEDIUMBLOB"
    
    #Picture.create :data => StringIO.new(File.new('public/images/avatar.png').read)
  end

  def self.down
    drop_table :pictures
  end
end
