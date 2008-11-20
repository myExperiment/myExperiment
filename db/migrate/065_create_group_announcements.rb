class CreateGroupAnnouncements < ActiveRecord::Migration
  # a table to store announcements for the groups;
  #
  # "user_id" is the user, who has made the announcement
  # (as in future more users apart from only the group admin might get
  #  access rights for making announcements)
  #
  # "public" flag will be used to keep record of whether the announcement
  # should be shown to anyone viewing the group's page ('true') or just to
  # the group members ('false'); by default this is private to group members
  
  def self.up
    create_table :group_announcements do |t|
      t.column :title, :string
      t.column :network_id, :integer
      t.column :user_id, :integer
      t.column :public, :boolean, :default => false
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :body, :text
      t.column :body_html, :text
    end
  end

  def self.down
    drop_table :group_announcements
  end
end
