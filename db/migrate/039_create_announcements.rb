class CreateAnnouncements < ActiveRecord::Migration
  def self.up
    create_table :announcements do |t|
      t.column :title, :string
      t.column :user_id, :integer
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :body, :text
      t.column :body_html, :text
    end
  end

  def self.down
    drop_table :announcements
  end
end
