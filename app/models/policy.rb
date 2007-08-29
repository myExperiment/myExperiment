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
  belongs_to :contributor, :polymorphic => true
  
  has_many :contributions,
           :dependent => :nullify
  
  has_many :permissions,
           :dependent => :destroy
  
  validates_presence_of :contributor
  
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
        return true if private?(category, contributor)
        
        # true if contribution.contributor and contributor are related and policy[category_protected]
        return true if (contribution.contributor.related? contributor and protected?(category))
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
                   "edit" => ["new", "create", "edit", "update"], 
                   "view" => ["index", "show", "tag", "search", "bookmark", "comment", "rate"],
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
    begin
      if (p = Permission.find_by_policy_id_and_contributor_id_and_contributor_type(id, contrib.id, contrib.class.to_s))
        return p.attributes["#{category}"] == true
      end
    rescue ActiveRecord::RecordNotFound
      return nil
    else
      return nil
    end
  end
end
