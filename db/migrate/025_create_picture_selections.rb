class CreatePictureSelections < ActiveRecord::Migration
  def self.up
    create_table :picture_selections do |t|
      t.column :user_id, :integer
      t.column :picture_id, :integer
      t.column :created_at, :Datetime
    end
  end

  def self.down
    drop_table :picture_selections
  end
end
