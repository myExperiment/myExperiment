# myExperiment: lib/policy_consistency_fixer.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

module Maintenance
  def check_and_fix_policies
    
    # output initial data about the script
    start_time = Time.now
    puts "\nThis script will process all Contribution objects in the DB to"
    puts "check for any inconsistencies or missing data in their policies."
    puts "\nNB! For updated policies the first line will always have policy id equal to 0"
    puts "- and this is fine, it's just a cloned copy of the original policy, which has id = 0"
    puts "as it was never saved to the DB."
    puts "\nNOTE: Policies are printed in a format:"
    puts "Policy[ id, (view_public, download_public, edit_public), (view_protected, download_protected, edit_protected) <=> (share_mode, update_mode)"
    puts "\n\nStarted at: " + start_time.to_s
    puts "This may take a while..."
    
    
    contributions_with_missing_policies = 0
    total_policies = 0
    err_policies = 0
    share_modes_missing = 0
    update_modes_missing = 0
    share_flag_mode_inconsistencies = 0
    update_flag_mode_inconsistencies = 0
    
    cur_policy_err = false
    cur_policy_copy = nil
    
    contributions = Contribution.find(:all)
    
    contributions.each do |c_ution|
      
      # find a policy for current contribution
      policy = c_ution.policy
      
      # check if policy exists
      if !policy
        contributions_with_missing_policies += 1
        printf("Contribution(ID = %d) doesn't have a policy associated with it\n", c_ution.id)
        next
      end
      
      # initialization
      total_policies += 1
      cur_policy_copy = nil
      cur_policy_copy = policy.clone  # (this will never be saved, so having a new policy object is fine)
      cur_policy_err = false
      
      # ====== Validation and fixing code for Policy object ======
      #    
      # IMPORTANT NOTE: If changes are made to the Ownership, Sharing and Permissions (OSP) model then 
      # this bit of code should either be updated or not used. It's been transferred to a script 
      # that goes through all policy records (rather than being executed every time .authorized? method
      # in Policy model was executed).
      #
      #
      # Due to many changes throughout the lifetime of the OSP model, 
      # some data inconsistency has been introduced (and has the potential to occur in future).
      # 
      # More specifically, due to the use of the bit fields:
      # - view_public
      # - view_protected
      # - download_public
      # - download_protected
      # - edit_public
      # - edit_protected
      # ... AND the use of the (newer) 'share_mode' and 'update_mode' fields. 
      #
      # The latter were introduced to carry out the mapping between the pre canned options in the UI,
      # and the underlying model.
      #
      # Therefore there are essentially 2 parts of the model that need to be in sync for OSP to work properly!
      #
      # So the following code attempts to validate the two models and fix them if any inconsistency is detected...
  
      # For each of the two main areas of OSP - sharing and updating (corresponding to the two 'mode' fields), do the following: 
      # - Check that the newer 'mode' field is present. If not, set it according to the values present in the bit fields.
      # - If the 'mode' field is present then check that the bit fields all match up. If not, set them accordingly.
      
      # NOTE(1): see \app\helpers\application_helper.rb > sharing_mode_text(..) method for the exact mapping.
  
      # NOTE(2): it was decided to make this code more 'live' than putting it in a script, so that it can continually attempt to fix 
      # issues in current data AND in any new data. Although, the potential risk that this causes is quite high. 
  
      # Sharing:
      
      if (policy.share_mode.nil?)
        # Note: some of the checks here do not take into account all the view and download bit fields because a dependency chain is assumed 
        # (ie: if public can download then friends MUST be able to download, even if the relevant bit field is set to false. 
        # In which case the bit fields will be in an inconsistent state, but should be fixed in the next run of this validation and self fix code).
        if (policy.view_public && policy.download_public)
          policy.share_mode = 0
        elsif (policy.view_public && !policy.download_public && policy.download_protected)
          policy.share_mode = 1
        elsif (policy.view_public && !policy.download_public && !policy.download_protected)
          policy.share_mode = 2
        elsif (!policy.view_public && !policy.download_public && policy.view_protected && policy.download_protected)
          policy.share_mode = 3
        elsif (!policy.view_public && !policy.download_public && policy.view_protected && !policy.download_protected)
          policy.share_mode = 4
        else
          policy.share_mode = 7
        end
        
        cur_policy_err = true
        share_modes_missing += 1
        policy.save
      end
      
      # Check if an inconsistency exists
      has_inconsistency = false
      case policy.share_mode
        when 0
          has_inconsistency = true unless (policy.view_public && policy.download_public && policy.view_protected && policy.download_protected)
        when 1
          has_inconsistency = true unless (policy.view_public && !policy.download_public && policy.view_protected && policy.download_protected)
        when 2
          has_inconsistency = true unless (policy.view_public && !policy.download_public && policy.view_protected && !policy.download_protected)
        when 3
          has_inconsistency = true unless (!policy.view_public && !policy.download_public && policy.view_protected && policy.download_protected)
        when 4
          has_inconsistency = true unless (!policy.view_public && !policy.download_public && policy.view_protected && !policy.download_protected)
        when 5, 6, 7
          has_inconsistency = true unless (!policy.view_public && !policy.download_public && !policy.view_protected && !policy.download_protected)
      end
      
      if has_inconsistency
        # Fix!
        case policy.share_mode
          when 0
            policy.view_public = true
            policy.download_public = true
            policy.view_protected = true 
            policy.download_protected = true
          when 1
            policy.view_public = true
            policy.download_public = false
            policy.view_protected = true 
            policy.download_protected = true
          when 2
            policy.view_public = true
            policy.download_public = false
            policy.view_protected = true 
            policy.download_protected = false
          when 3
            policy.view_public = false
            policy.download_public = false
            policy.view_protected = true 
            policy.download_protected = true
          when 4
            policy.view_public = false
            policy.download_public = false
            policy.view_protected = true 
            policy.download_protected = false
          when 5, 6, 7
            policy.view_public = false
            policy.download_public = false
            policy.view_protected = false 
            policy.download_protected = false
        end
        
        cur_policy_err = true
        share_flag_mode_inconsistencies += 1
        policy.save
      end
      
      
      # Updating:
  
      if (policy.update_mode.nil?)
        policy.update_mode = policy.determine_update_mode(c_ution)
        cur_policy_err = true
        update_modes_missing += 1
        policy.save if policy.update_mode
      end
      
      # Check if an inconsistency exists
      has_inconsistency = false
      case policy.update_mode
        when 0
          # for this mode it's not really possible to check anything - both 'edit_public' and 'edit_protected'
          # can be either 0 or 1, and these settings -anyways- override view & download settings (in the
          # authorisation, but NOT in the DB); so should be as it is.
          # COMMENTED OUT
          # has_inconsistency = true if (policy.edit_public != (policy.view_public && policy.download_public))
          # has_inconsistency = true if (policy.edit_protected != (policy.view_protected && policy.download_protected))
          # END
        when 1
          has_inconsistency = true if (policy.edit_public || !policy.edit_protected)
        when 2, 3, 4, 5, 6, 7
          has_inconsistency = true unless (!policy.edit_public && !policy.edit_protected)
      end
      
      if has_inconsistency
        # Fix!
        case policy.update_mode
          when 0
            # This cannot be used, see explanation for update mode 0 above.
            # COMMENTED OUT
            # policy.edit_protected = (policy.view_protected && policy.download_protected)
            # policy.edit_public    = (policy.view_public    && policy.download_public)
            # END
          when 1
            policy.edit_protected = true
            policy.edit_public = false
          when 2, 3, 4, 5, 6, 7
            policy.edit_protected = false
            policy.edit_public    = false
        end
        
        cur_policy_err = true
        update_flag_mode_inconsistencies += 1
        policy.save
      end
      
      
      
      # ======= all processing for current policy finished =======
      # (output any errors now & update stats)
      if cur_policy_err
        err_policies += 1
        
        puts ""
        print_policy(cur_policy_copy)
        puts "    vvvv                     vvvv                       vvvv"
        print_policy(policy)
        puts ""
      end
      
    end
    
    # checking-fixing all policies done, output stats
    end_time = Time.now
    puts "\n\nFinished at:  " + end_time.to_s
    puts "Processing took:  " + (end_time - start_time).to_s + "\n"
    puts "Missing policies: " + contributions_with_missing_policies.to_s
    puts "Total policies:       #{total_policies}"
    puts "Policies with errors: #{err_policies}\n"
    puts "Policies with missing share modes:  #{share_modes_missing}"
    puts "Policies with missing update modes: #{update_modes_missing}"
    puts "Share flag-mode inconsistencies:    #{share_flag_mode_inconsistencies}"
    puts "Update flag-mode inconsistencies:   #{update_flag_mode_inconsistencies}\n\n\n"
    
  end
  
  
  def print_policy(policy)
    printf("Policy [id -> %4d, (%s, %s, %s), (%s, %s, %s) <=> (%d, %d) ]\n", policy.id, policy.view_public.to_s, policy.download_public.to_s, policy.edit_public.to_s, policy.view_protected.to_s, policy.download_protected.to_s, policy.edit_protected.to_s, policy.share_mode, policy.update_mode)
  end
  
end