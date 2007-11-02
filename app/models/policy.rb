##
##
## myExperiment - a social network for scientists
##
## Copyright (C) 2007 University of Manchester/University of Southampton
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License
## as published by the Free Software Foundation; either version 3 of the
## License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program; if not, see http://www.gnu.org/licenses
## or write to the Free Software Foundation,Inc., 51 Franklin Street,
## Fifth Floor, Boston, MA 02110-1301  USA
##
##

class Policy < ActiveRecord::Base
  #validates_uniqueness_of :name, :scope => [:contributor_id, :contributor_type]
  
  belongs_to :contributor, :polymorphic => true
  
  has_many :contributions,
           :dependent => :nullify,
           :order => "contributable_type ASC"
  
  has_many :permissions,
           :dependent => :destroy,
           :order => "created_at ASC"
  
  validates_presence_of :contributor, :name
  
  def authorized?(action_name, c_ution=nil, c_utor=nil)
    if c_ution
      # false unless correct policy for contribution
      return false unless c_ution.policy.id.to_i == id.to_i
    end
      
    # false unless action can be categorized
    return false unless category = categorize(action_name)
      
    unless c_utor.nil?
      if c_ution
        # true if owner of contribution or administrator of contribution.policy
        return true if (c_ution.owner?(c_utor) or c_ution.admin?(c_utor))
      else
        # true if administrator of self
        return true if admin?(c_utor)
      end
        
      # true if permission and permission[category]
      private = private?(category, c_utor)
      return private unless private.nil?
        
      if c_ution
        # true if contribution.contributor and contributor are related and policy[category_protected]
        return true if (c_ution.contributor.protected? c_utor and protected?(category))
      else
        # true if policy.contributor and contributor are related and policy[category_protected]
        return true if (self.contributor.protected? c_utor and protected?(category))
      end
    end
      
    # true if policy[category_public]
    return public?(category)
  end
  
  def admin?(c_utor)
    return false unless c_utor
    
    contributor_id.to_i == c_utor.id.to_i and contributor_type.to_s == c_utor.class.to_s
  end
  
  # THIS IS THE DEFAULT POLICY (see /app/views/policies/_list_form.rhtml)
  # IT IS CALLED IN contribution.rb::authorized?
  def self._default(c_utor, c_ution=nil)
    rtn = Policy.new(:name => "Friends can download and view",
                     :contributor => c_utor,
                     :view_public => false,        # anonymous can't view
                     :download_public => false,    # anonymous can't download
                     :edit_public => false,        # anonymous can't edit
                     :view_protected => true,      # friends can view
                     :download_protected => true,  # friends can download
                     :edit_protected => false)     # friends can't edit
                     
    c_ution.policy = rtn unless c_ution.nil?
    
    return rtn
  end
  
private

  # categorize action names here (make sure you include each one as an 
  # xxx_public and xxx_protected column in ++policies++ and an xxx 
  # column in ++permissions+)
  @@categories = { "download" => ["download"], 
                   "edit" => ["new", "create", "edit", "update", "new_version"], 
                   "view" => ["index", "show", "search", "bookmark", "comment", "rate", "tag"],
                   "owner" => ["destroy"] } # you don't need a boolean column for this but you do need to categorize 'owner only' actions!
  
  # the policy class contains a hash table of action (method) names and their categories
  # all methods are one of the three categories: download, edit and view
  def categorize(action_name)
    @@categories.each do |key, value|
      return key if value.include? action_name
    end
      
    return nil
  end
  
  def public?(category)
    attributes["#{category}_public"] == true
  end
  
  def protected?(category)
    attributes["#{category}_protected"] == true
  end
  
  def private?(category, contrib)
    found = []
    
    # call recursive method
    private!(category, contrib, found)
    
    unless found.empty?
      rtn = nil
      
      found.each do |f|
        id, type, result = f[0], f[1], f[2]
        
        case type.to_s
        when "User"
          return result
        when "Network"
          if rtn.nil?
            rtn = result
          else
            rtn = result if result == true
          end
        else
          # do nothing!
        end
      end
      
      return rtn
    else
      return nil
    end
  end
  
  def private!(category, contrib, found)
    result = permission?(category, contrib)
    found << [contrib.id, contrib.class.to_s, result] unless result.nil?
    
    case contrib.class.to_s
    when "User"
      contrib.networks.each do |n| # test networks that user is a member of 
        private!(category, n, found)
      end
      
      contrib.networks_owned.each do |n| # test networks owned by user
        private!(category, n, found)
      end
    when "Network"
      # network related tests
    else
      # do nothing!
    end
  end
  
  def permission?(category, contrib)
    if (p = Permission.find(:first, 
                            :conditions => ["policy_id = ? AND contributor_id = ? AND contributor_type = ?", 
                                            self.id, contrib.id, contrib.class.to_s]))
      return p.attributes["#{category}"]
    else
      return nil
    end
  end
end
