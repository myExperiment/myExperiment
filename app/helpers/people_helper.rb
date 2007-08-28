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

module PeopleHelper

  def friendship_actions(person, user)
    if person.id != user.id
      if user.friends_with?(person)
        content_tag(:p, link_to('Remove friend', {:controller => 'people', :action => 'remove_friend',
                                :id => person}, :method => :post,
                                :confirm => "Are you sure yo want to remove " + h(person.profile.name) + " from your friends?"))
      else
        if user.pending_friends_for_me.include? person
          content_tag(:p, link_to('Accept friendship', {:controller => 'people', :action => 'accept_friend',
                                  :id => person})) +
          content_tag(:p, link_to('Decline friendship', {:controller => 'people', :action => 'decline_friend',
                                  :id => person}))
        else
          if user.pending_friends_by_me.include? person
            content_tag(:p, 'Friend requested')
          else
            content_tag(:p, link_to('Add friend', {:controller => 'people', :action => 'add_friend',
                                    :id => person}, :method => :post))
          end
        end
      end
    end
  end

end
