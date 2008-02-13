# myExperiment: app/models/taverna_enactor.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class TavernaEnactor < ActiveRecord::Base
  acts_as_runnable
  
  belongs_to :contributor, :polymorphic => true
  
  # Note: at the moment (Feb 2008), only the creator of the TavernaEnactor is authorized 
  # OR the administrator of the Group that owns the TavernaEnactor. 
  def authorized?(action_name, c_utor=nil)
    return false if c_utor.nil?
    
    # Cannot ask authorization for a 'Network' contributor
    return false if c_utor.class.to_s == 'Network' 
    
    case self.contributor_type.to_s
    when "User"
      return self.contributor_id.to_i == c_utor.id.to_i
    when "Network"
      return self.contributor.owner?(c_utor.id)
    else
      return false
    end 
  end
end
