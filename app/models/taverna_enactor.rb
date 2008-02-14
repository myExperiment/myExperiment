# myExperiment: app/models/taverna_enactor.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'acts_as_runner'

class TavernaEnactor < ActiveRecord::Base
  
  acts_as_runner
  
  belongs_to :contributor, :polymorphic => true
  validates_presence_of :contributor
  
  validates_presence_of :username
  validates_presence_of :crypted_password
  validates_presence_of :url
  validates_presence_of :title
  
  encrypts :password, :mode => :symmetric, :key => SYM_ENCRYPTION_KEY
  
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
  
  def service_client
    @client = new Enactor::Client.new(self.url, self.username, self.crypted_password.decrypt) unless @client
    return @client
  end
  
  def service_valid?
    service_client.service_valid?
  end
  
end
