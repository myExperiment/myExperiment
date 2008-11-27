class CreateActivityLimits < ActiveRecord::Migration
  
  # This table will hold the state of various limits that can be
  # imposed on the user / group actions - for example,
  # limits on the number of internal messages that can be sent over
  # period of time by some user; or number of invitations that the
  # user can send 
  
  def self.up
    create_table :activity_limits do |t|
      # contributor (e.g. user or group that is limited)
      t.column :contributor_type, :string, :null => false
      t.column :contributor_id, :integer, :null => false
      
      # which action for the contributor is limited
      t.column :limit_feature, :string, :null => false
      
      # "limit_max" - maximum number of times (NULL for unlimited) the action can be executed over
      # "limit_frequency" period (in hours); "limit_frequency" set to NULL means that the limit is not periodic
      t.column :limit_max, :integer
      t.column :limit_frequency, :integer
      
      # number of times the action has already been executed since the last reset (governed by "limit_frequency")
      # (can't be NULL - doesn't make sense to have NULL value for the counter)
      t.column :current_count, :integer, :null => false
      
      # date/time after which "current_count" is to be reset to "limit_max" (for periodic limits - such as daily message limit)
      # (NULL to indicate that reset should never happen and the limit is absolute, i.e. non-periodic)
      # (the code will assume that if either --or both-- of "limit_frequency" and "reset_after" are NULLs, the limit is non-periodic)
      t.column :reset_after, :datetime
      
      # date/time after which promotion to the next level (with, probably, higher "limit_max" should happen)
      # (NULL to indicate that promotion should never happen and the user is to stay at the same level)
      t.column :promote_after, :datetime
    end
  end

  def self.down
    drop_table :activity_limits
  end
end
