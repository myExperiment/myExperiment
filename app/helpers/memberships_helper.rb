# myExperiment: app/helpers/memberships_helper.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

module MembershipsHelper
  
  # helper method to display the 'pending approval from <?>' message
  def pending_approval_message(approval_allowed, is_invite)
    if approval_allowed
      return "Your confirmation needed"
    else
      msg = "Waiting confirmation from "
      return msg + (is_invite ? "user" : "group admin")
    end
  end
  
  # helper method to display which action exactly happened with respect to
  # current viewer and invitation / request
  #
  # NB! This method is to be called when the mebership is NOT yet accepted!!
  #
  # Returns: the string 
  def membership_invite_request_action_message(approval_allowed, is_invite, username_dropdown)
    if approval_allowed 
      if is_invite
        return "You have received an invitation to become a member of:"
      else
        return "#{username_dropdown} has sent you a request to join:"
      end
    else
      if is_invite
        return "You have invited #{username_dropdown} to join:" 
      else
        return "You have requested to become a member of:"
      end
    end
  end
  
end
