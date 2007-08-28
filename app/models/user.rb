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

# this model expects a certain database layout and its based on the name/login pattern. 
class User < ActiveRecord::Base
  # display_name, email, admin? and logged_in? are all extended from UserInit
  include SavageBeast::UserInit
  
  def display_name 
    self.profile.name
  end
  
  def email
    self.profile.email
  end
  
  def admin?
    false # no user is overall administrator
  end
  
  def logged_in?
    current_user != 0
  end

  def self.get(openid_url)
    find_first(["openid_url = ?", openid_url])
  end  
  def say_in_channel(channel, say)
    Channelmessage.new(:channel => channel, :topic_id => channel.topic_id, :content => sanitize(say), :sender => self).save
  end

  def action_in_channel(channel, say)
    Channelmessage.new(:channel => channel, :topic_id => channel.topic_id, :content => sanitize(say), :sender => self, :level => 'action').save
  end
  
  def topic_change_in_channel(channel, newtopic)
    Channelmessage.new(:channel => channel, :topic_id => channel.topic_id, :content => "changes topic to: '"+sanitize(newtopic)+"'", :sender => self, :level => 'topicchange').save
  end
  
  def joins_channel(channel)
    Channelmessage.new(:channel => channel, :topic_id => channel.topic_id, :sender => self, :content => "joins the channel", :level => 'sys').save
  end
  
  def leaves_channel(channel)
    Channelmessage.new(:channel => channel, :topic_id => channel.topic_id, :sender => self, :content => "left the channel", :level => 'sys').save
  end

  def sanitize(say)
    say.gsub!(/\</, '&lt;')
    say.gsub!(/\>/, '&gt;')
    say.strip!();
    say
  end
  
  def profile_name_unique()
     pcount = Profile.count(:conditions => ["name = ?", self.profile.name])
     return " ("+self.profile.unique+")" if (pcount>1)
     return "";
  end
  
  has_one :profile
  
  has_many :pictures
  
  has_many :workflows
  
  has_many :sharing_users
  
  has_many :comments
          
  has_many_friends
  has_many :lines, :foreign_key => 'sender_id'
  
  has_many :memberships
  
  has_many :histories
  
  def friend?(user=current_user)
    Friendship.find_by_user_id_and_friend_id(self.id, user.id, :conditions => ["accepted_at < ?", Time.now]) # is the owner of the wf "friends with me"
  end
  
  protected
  
  validates_uniqueness_of :openid_url, :on => :create
  validates_presence_of :openid_url
    
end
