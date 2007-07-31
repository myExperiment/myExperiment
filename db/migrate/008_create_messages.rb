class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.column :from, :integer
      t.column :to, :integer
      t.column :subject, :string
      t.column :body, :text
      t.column :reply_id, :integer
      t.column :created_at, :datetime
      t.column :read_at, :datetime
    end
  end

  def self.down
    drop_table :messages
  end
end
