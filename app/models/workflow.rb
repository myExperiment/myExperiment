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


class Workflow < ActiveRecord::Base
  
  file_column :scufl

  file_column :image, :magick => {
    :versions => {
      :thumb =>  {:size => "100x100!"}, 
      :medium => {:size =>"650x300>" }
    }
  }

  acts_as_taggable
  
  acts_as_rateable
  
  acts_as_commentable

  acts_as_bookmarkable

  acts_as_ferret :fields => { :title => { :store => :yes }, 
                              :description => { :store => :yes }, 
                              :tag_list => { :store => :yes },
                              :rating => { :index => :untokenized } }

  belongs_to :user
  
  has_many :sharing_users
  has_many :sharing_projects
  has_many :jobs

  validates_presence_of :title
  
  def authorized?(user, permission)
    if owner? user
      return true
    end
    
    if permission == "r" or permission == "read"
      acl = self.acl_r
    elsif permission == "m" or permission == "modify"
      acl = self.acl_m
    elsif permission == "d" or permission == "delete"
      acl = self.acl_d
    else
      return false
    end
    
    # 0 - owner only (owner for 1-8 incl.)
    # 1 - projects
    # 2 - users
    # 3 - users and projects
    # 4 - friends
    # 5 - friends and projects
    # 6 - friends and users
    # 7 - friends, users and projects
    # 8 - ALL
    
    if acl == 1 and member_of_sharing_project? user
      return true
    elsif acl == 2 and sharing_user? user
      return true
    elsif acl == 3 and (sharing_user? user or member_of_sharing_project? user)
      return true
    elsif acl == 4 and (self.user.friend? user or user.friend? self.user)
      return true
    elsif acl == 5 and (self.user.friend? user or user.friend? self.user or member_of_sharing_project? user)
      return true
    elsif acl == 6 and (self.user.friend? user or user.friend? self.user or sharing_user? user)
      return true
    elsif acl == 7 and (self.user.friend? user or user.friend? self.user or sharing_user? user or member_of_sharing_project? user)
      return true
    elsif acl == 8
      return true
    else
      return false
    end
    
    return false
  end
  
  def member_of_sharing_project?(member)
    if (s = SharingProject.find_by_workflow_id(self.id)) and Membership.find_by_user_id_and_project_id(member.id, s.project_id)
      return true
    else
      return false
    end
  end
  
  def sharing_project?(project)
    if SharingProject.find_by_workflow_id_and_project_id(self.id, project.id)
      return true
    else
      return false
    end
  end

  def sharing_user?(user)
    if SharingUser.find_by_workflow_id_and_user_id(self.id, user.id)
      return true
    else
      return false
    end
  end
  
  def owner?(owner)
    if self.user_id.equal? owner.id
      return true
    else
      return false
    end
  end

end
