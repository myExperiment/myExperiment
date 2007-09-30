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
           :dependent => :nullify
  
  has_many :permissions,
           :dependent => :destroy,
           :order => "created_at ASC"
  
  validates_presence_of :contributor, :name
  
  def authorized?(action_name, contribution, contributor=nil)
    begin
      # false unless correct policy for contribution
      return false unless contribution.policy.id.to_i == id.to_i
      
      # false unless action can be categorized
      return false unless category = categorize(action_name)
      
      unless contributor.nil?
        # true if owner of contribution or administrator of contribution.policy
        return true if (contribution.owner?(contributor) or contribution.admin?(contributor))
        
        # true if permission and permission[category]
        private = private?(category, contributor)
        return private unless private.nil?
        
        # true if contribution.contributor and contributor are related and policy[category_protected]
        return true if (contribution.contributor.protected? contributor and protected?(category))
      end
      
      # true if policy[category_public]
      return public?(category)
    rescue
      # all errors return false
      return false
    else
      # end of method
      return false
    end
  end
  
  def admin?(c_utor)
    contributor_id.to_i == c_utor.id.to_i and contributor_type.to_s == c_utor.class.to_s
  end
  
private

  # categorize action names here (make sure you include each one as an 
  # xxx_public and xxx_protected column in ++policies++ and an xxx 
  # column in ++permissions+)
  @@categories = { "download" => ["download"], 
                   "edit" => ["new", "create", "edit", "update", "tag"], 
                   "view" => ["index", "show", "search", "bookmark", "comment", "rate"],
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
