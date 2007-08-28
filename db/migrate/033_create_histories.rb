class CreateHistories < ActiveRecord::Migration
  def self.up
    create_table :histories do |t|
      t.column :user_id, :integer
      t.column :execution_time, :datetime
      t.column :action, :string, :null => false
      t.column :controller, :string, :null => false
      t.column :params_id, :integer
    end
  end

  def self.down
    drop_table :histories
  end
end
