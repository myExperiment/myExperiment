class AddExperiments < ActiveRecord::Migration

  def self.up
    create_table :experiments, :force => true do |t|
      t.column :title, :string, :limit => 50, :default => ""
      t.column :created_at, :datetime, :null => false
      t.column :user_id, :integer, :default => 0, :null => false
    end

    add_index :experiments, ["user_id"], :name => "fk_experiments_user"
  end

  def self.down
    drop_table :experiments
  end

end
