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

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def channelmessage_content(channelmessage)
    if (channelmessage.level)
      %(<div class="channelmessage #{channelmessage.level}" id="channelmessage-#{channelmessage.id}"><span class="time">#{channelmessage.created_at.strftime('%R')}</span> <span class="sender">#{channelmessage.sender.profile.name}<small>#{channelmessage.sender.profile_name_unique}</small> </span><span class="content">#{channelmessage.content.gsub(/\n/,'<br/>')}</span></div>)
    else
      %(<div class="channelmessage #{channelmessage.level}" id="channelmessage-#{channelmessage.id}"><span class="time">#{channelmessage.created_at.strftime('%R')}</span> <span class="sender">#{channelmessage.sender.profile.name}<small>#{channelmessage.sender.profile_name_unique}</small>: </span><span class="content">#{channelmessage.content.gsub(/\n/,'<br/>')}</span></div>)
    end
  end

  def tag_cloud(tags, classes)

    max, min = 0, 0
    tags.each { |t|
      max = t.count.to_i if t.count.to_i > max
      min = t.count.to_i if t.count.to_i < min
    }

    divisor = ((max - min) / classes.size) + 1

    tags.each { |t|
      yield t.name, classes[(t.count.to_i - min) / divisor]
    }

  end

 # from http://www.igvita.com/blog/2006/09/10/faster-pagination-in-rails/
 def windowed_pagination_links(pagingEnum, options)
    link_to_current_page = options[:link_to_current_page]
    always_show_anchors = options[:always_show_anchors]
    padding = options[:window_size]

    current_page = pagingEnum.page
    html = ''

    #Calculate the window start and end pages
    padding = padding < 0 ? 0 : padding
    first = pagingEnum.page_exists?(current_page  - padding) ? current_page - padding : 1
    last = pagingEnum.page_exists?(current_page + padding) ? current_page + padding : pagingEnum.last_page

    # Print start page if anchors are enabled
    html << yield(1) if always_show_anchors and not first == 1

    # Print window pages
    first.upto(last) do |page|
      (current_page == page && !link_to_current_page) ? html << page : html << yield(page)
    end

    # Print end page if anchors are enabled
    html << yield(pagingEnum.last_page) if always_show_anchors and not last == pagingEnum.last_page
    html
  end

  def profile_link(user)
    link_to h(user.profile.name), :controller => 'profile', :action => 'show', :id => user.id
  end

  def message_status(user)
    count = Message.count(["to_id = ? and read_at IS NULL", user.id])
    result = link_to('Inbox', {:controller => 'messages'}, :id => 'inbox')
    result << ' (' << link_to(count, :controller => 'messages') << ')' if count > 0
    result
  end

  def avatar(user_id, size = '100x100', link_to_profile = true)
    if user = User.find(user_id)
      if user.avatar
        avatar_url = url_for(:controller => 'pictures', :action => 'show', :id => user.avatar, :size => size)
        avatar_image = image_tag(avatar_url, :border => '1', :title => h(user.profile.name))
        
        if link_to_profile
          return link_to(avatar_image, :controller => 'profile', :action => 'show', :id => user_id)
        else
          return avatar_image
        end
      else
        # create "alan" avatar
        return image_tag("avatar.png", :border => '1', :title => h(user.profile.name), :size => size)
      end
    else
      flash[:notice] = "User #{userid} not found"
    end   
  end

end
