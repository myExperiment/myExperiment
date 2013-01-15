class MoveLayoutToPolicy < ActiveRecord::Migration
  def self.up
    # Add column to policies
    add_column :policies, :layout, :string
    # Copy values
    ActiveRecord::Base.record_timestamps = false
    execute 'UPDATE policies,contributions SET policies.layout = contributions.layout WHERE policies.id = contributions.policy_id'
    ActiveRecord::Base.record_timestamps = true
    # Remove column from contributions
    remove_column :contributions, :layout
  end

  def self.down
    add_column :contributions, :layout, :string
    ActiveRecord::Base.record_timestamps = false
    execute 'UPDATE policies,contributions SET contributions.layout = policies.layout WHERE policies.id = contributions.policy_id'
    ActiveRecord::Base.record_timestamps = true
    remove_column :policies, :layout
  end
end
