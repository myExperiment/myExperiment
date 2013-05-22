class ActivityLimit < ActiveRecord::Base
  
  # the single point in the application governing validation of all features that have
  # limited allowance of usage (e.g. 5 messages a day, etc)
  def self.check_limit(contributor, limit_feature, update_counter=true)
    time_now = Time.now
    limit_save_required = false
    
    if (limit = ActivityLimit.find(:first, :conditions => ["contributor_type = ? AND contributor_id = ? AND limit_feature = ?", contributor.class.name, contributor.id, limit_feature]))
      # limit exists - check its validity
      if (limit.limit_frequency && limit.reset_after && time_now > limit.reset_after)
        # "reset_after" / "limit_frequency" are not NULL - so the limit is periodic;
        # now it's the time to reset the counter to zero - no matter what its value was before
        # (this will never be executed for non-periodic counters)
        limit.current_count = 0
        limit.reset_after = time_now + limit.limit_frequency.hours
        limit_save_required = true

        # also check if the contributor needs to be "promoted" to the next level --
        # e.g. in the first month of membership on myExperiment one can send 10 messages daily,
        # but after that can send 15 (because the user becomes more "trusted")
        if (limit.promote_after && time_now > limit.promote_after)
          absolute_max_limit_value = Conf.activity_limits[limit_feature]["max_value"]
          limit_increment_value = Conf.activity_limits[limit_feature]["promote_increment"]
          promote_every = Conf.activity_limits[limit_feature]["promote_every"]
          
          if limit_increment_value
            if absolute_max_limit_value
              # absolute max value set -->
              # increase the limit only if not exceeded absolute maximum just yet
              if (limit.limit_max < absolute_max_limit_value)
                limit.limit_max += limit_increment_value
                limit.promote_after = (promote_every ? (time_now + promote_every.days) : nil)
               else
                # absolute maximum already reached / exceeded, disable further promotions
                limit.promote_after = nil
              end
              
              # make sure that it's not set to exceed the absolute maximum
              # (which can happen if increment is not factor of the absolute maximum value)
              if (limit.limit_max > absolute_max_limit_value)
                limit.limit_max = absolute_max_limit_value
              end
            else
              # absolute value not set --> simply increment
              limit.limit_max += limit_increment_value
              limit.promote_after = (promote_every ? (time_now + promote_every.days) : nil)
            end
          else 
            # increment not set - this will be a one-time promotion
            # (if the absolute max value is set - set limit to it; if not - the feature becomes unlimited)
            limit.limit_max = absolute_max_limit_value
            limit.promote_after = nil
            
            if limit.limit_max.nil?
              # the feature has become unlimited; no need to reset the counter anymore - 
              # just keep it running to see usage of the feature by the user
              limit.limit_frequency = nil
              limit.reset_after = nil
            end
          end   
        end # END of PROMOTION code
        
      end # END of COUNTER RESET code
      
    else
      # limit doesn't exist yet - create it, then proceed to validation and saving
      limit_frequency = Conf.activity_limits[limit_feature]["frequency"]
      promote_every = Conf.activity_limits[limit_feature]["promote_every"]
      
      limit = ActivityLimit.new(:contributor_type => contributor.class.name, :contributor_id => contributor.id,
                                :limit_feature => limit_feature, 
                                :limit_max => Conf.activity_limits[limit_feature]["start_value"],
                                :limit_frequency => limit_frequency,
                                :reset_after => (limit_frequency ? (time_now + limit_frequency.hours) : nil),
                                :promote_after => (promote_every ? (time_now + promote_every.days) : nil),
                                :current_count => 0)
                                
      limit_save_required = true
    end
    
    
    # decide if the requested action is allowed - check on the current counter value
    action_allowed = true
    if limit.limit_max
      # (NULL in "limit_max" would mean unlimited allowance - not this case)
      # deny the action if the "current_count" is equal / exceeded the "limit_max" value
      action_allowed = false if (limit.current_count >= limit.limit_max)
    end
    
    # update counter for the "current" action
    if action_allowed && update_counter
      limit.current_count += 1
      limit_save_required = true
    end
    limit.save if limit_save_required # saves all changes (including counter resets, etc) if any were made
    
    # return if action is allowed / denied and when the next reset is going to be (nil for non-periodic counters) 
    return [action_allowed, (limit.reset_after ? (limit.reset_after - time_now) : nil)]
  end
  
  
  # returns the remaining allowance (and the date/time when it finishes) for the limited feature;
  # [NIL, NIL] if unlimited or limit doesn't exist 
  def self.remaining_allowance(contributor, limit_feature)
    limit = ActivityLimit.find(:first, :conditions => ["contributor_type = ? AND contributor_id = ? AND limit_feature = ?", contributor.class.name, contributor.id, limit_feature])
    return [nil, nil] unless limit
    return [(limit.limit_max ? (limit.limit_max - limit.current_count) : nil), limit.reset_after]
  end
  
end
