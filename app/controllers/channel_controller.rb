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

class ChannelController < ApplicationController
  
  before_filter :make_channel_name
  

  def visit
    if (user_on_project(session[:user_id],params[:id]))
      if (not params[:messagesfrom])
        params[:messagesfrom]='Today'
      end
	  if (params[:settopic])
        set_topic(params[:topic])
      end
	  @page_class = params[:style] if params[:style]
      @user = User.find(session[:user_id])
	  session[:user_id] = @user.id
      if (params[:id]) 
        params[:leaveto]="window.location='/projects/"+params[:id]+"'"
      else
        params[:leaveto]="window.location='/chat/list/'" 
      end  
	  if (Channel.exists?(:project_id => params[:id]))
	    @channel = Channel.find_by_project_id(params[:id])
	  else
	    @channel=Channel.new(:project_id => params[:id], :title => get_channel_title, :name => make_channel_name)
	    @channel.save
	  end
      if (@channel.topic_id==0)
        channel_topic=get_channel_topic(@channel)
   	    @channeltopic=ChannelTopic.new(:title => channel_topic, :channel_id => @channel.id)
   	    @channeltopic.save
   	    @channel.topic_id=@channeltopic.id
	    @channel.save
   	  else
   	    @channeltopic=ChannelTopic.find(@channel.topic_id)
      end
      unless @channel.users.include?(@user)
        @user.joins_channel(@channel)
      	@channel.users.push_with_attributes(@user, {:last_seen => Time.now, :cu_id => ''})
      end
      @chan="lastid_"+@channel.id.to_s
      @lastchannelmessage = Channelmessage.find(:first, :conditions => ["channel_id = ?", @channel.id],  :order => "id DESC")
      if (@lastchannelmessage) 
        session[@chan]= @lastchannelmessage.id
      else
        session[@chan]= '0'
      end
      startmessage = @channel.get_first_channelmessage(params[:messagesfrom])
      if (startmessage.to_i > session[@chan].to_i)
        session[@chan]= startmessage
      end
      if (params[:save]) 
        save_chat(params[:messagesfrom])
      end
    else
      redirect_to :controller => 'projects', :action => 'channelblock', :id => params[:id]
    end
  end
  
  def part
    get_channel_and_user
    @user.leaves_channel(@channel) 
    @channelmessage = Channelmessage.find(:first, :order => "id DESC", :conditions => ["sender_id = ?", @user.id])
    @channelsuser = @channel.users.find(@user)
    @channel.users.delete(@user) 
  end
  
  def preview
    if (user_on_project(session[:user_id],params[:id]))
      params[:messagesfrom]='Today'
      @page_class = params[:style] if params[:style]
      if (Channel.exists?(:project_id => params[:id]))
        @channel = Channel.find_by_project_id(params[:id])
      else
        @channel=Channel.new(:project_id => params[:id], :title => get_channel_title, :name => make_channel_name)
        @channel.save
      end
      if (@channel.topic_id==0)
        channel_topic=get_channel_topic(@channel)
   	@channeltopic=ChannelTopic.new(:title => channel_topic, :channel_id => @channel.id )
   	@channeltopic.save
   	@channel.topic_id=@channeltopic.id
	@channel.save
      else
        @channeltopic=ChannelTopic.find(@channel.topic_id)
      end
      @chan="lastid_"+@channel.id.to_s
      @lastchannelmessage = Channelmessage.find(:first, :conditions => ["channel_id = ?", @channel.id],  :order => "id DESC")
      if (@lastchannelmessage) 
        session[@chan] = @lastchannelmessage.id
      else
        session[@chan] = '0'
      end
      startmessage = @channel.get_first_channelmessage(params[:messagesfrom])
      if (startmessage.to_i > session[@chan].to_i)
        session[@chan]= startmessage
      end
      params[:channelname]=@channel_name
    else
      redirect_to :controller => 'projects', :action => 'channelblock', :id => params[:id]
    end
  end
  # Post a user's message to a channel
  def say
    return false unless request.xhr?
    get_channel_and_user
    
    # Get the message
    channelmessage = params[:channelmessage]
   
    return false unless channelmessage
    if (channelmessage.length > 1000)
	    #or channelmessage.include?('\n'))
		aerror='error'
    elsif (channelmessage.match(/^\/\w+/))
      # It's an IRC style command
      
      command, arguments = channelmessage.scan(/^\/(\w+)(.*?)$/).flatten
      logger.info(command)
      case command
        when 'me'
          @user.action_in_channel(@channel, arguments)
          @channelmessage = Channelmessage.find(:first, :order => "id DESC", :conditions => ["sender_id = ?", @user.id])
        when 'topic'
          set_topic(arguments)
        when 'leave'
          part
        when 'save'
          #@user.say_in_channel(@channel, command+arguments)
          @channelmessages=@channel.latest_channelmessages
          pagetitle=@channel.title+": Chat Log "+Time.now.to_s
          pagename=pagetitle.gsub(/[^\w\.]+/, '_')
	      #pagetext=make_small_title(pagetitle)
	      pagetext=" "
 	      for chanmessage in @channelmessages
 	        pagetext << get_channelmessage_printout(chanmessage)
          end
         Page.new(:name => pagename, :created_at => Time.now, :user_id => @user.id, :content => pagetext).save
        when 'clear'
          #@user.say_in_channel(@channel, command+arguments)
          Channelmessage.delete_all(["channel_id = ?", @channel.id])
        else
          @user.say_in_channel(@channel, "ILLEGAL COMMAND: "+command)
          @channelmessage = Channelmessage.find(:first, :order => "id DESC", :conditions => ["sender_id = ?", @user.id]) 
         # return false   
        end
    else
      @user.say_in_channel(@channel, channelmessage)
      @channelmessage = Channelmessage.find(:first, :order => "id DESC", :conditions => ["sender_id = ?", @user.id])
    end
    
    render :layout => false
  end

  # Get the latest messages since the user last got any
  def get_latest_channelmessages
    return false unless request.xhr?
    get_channel_and_user
    @chan="lastid_"+@channel.id.to_s
   #  @channelmessages = @channel.channelmessages.since(session[:last_retrieval])
   #  session[:last_retrieval] = Time.now
    @channelmessages = Channelmessage.find(:all, :conditions => ["channel_id = ? AND id > ?", @channel.id, session[@chan]],  :order => "id ASC")
    if (@channelmessages.length > 0)
      session[@chan] = @channelmessages.last.id
    end
    render :layout => false
  end
  
  # Get a list of users for the channel and clean up any who left
  def get_user_list
    return false unless request.xhr?
    get_channel_and_user
     # Announce any users who just left
    if @channel.users_just_left
      for user in @channel.users_just_left
        user.leaves_channel(@channel)
      end
    end
     # Do a clean up of users in the channel
    @channel.users.cleanup
    # Tell the database we're still alive
    @channelsuser = @channel.users.find(@user)
    @channel.users.delete(@user)
    @channel.users.push_with_attributes(@user,{:last_seen => Time.now, :cu_id => @channelsuser.cu_id})
    render :layout => false
  end
  
  # Get the latest messages since the user last got any
  def get_latest_channelmessages_preview
    return false unless request.xhr?
    get_channel
    @chan="lastid_"+@channel.id.to_s
 #   @channelmessages = @channel.channelmessages.since(session[:last_retrieval])
  #  session[:last_retrieval] = Time.now
     @channelmessages = Channelmessage.find(:all, :conditions => ["channel_id = ? AND id > ?", @channel.id, session[@chan]], :order => "id ASC")
    if (@channelmessages.length > 0)
      session[@chan] = @channelmessages.last.id
    end
    render :layout => false
  end
  
  # Get a list of users for the channel and clean up any who left
  def get_user_list_preview
    return false unless request.xhr?
    get_channel
    
    # Announce any users who just left
    if @channel.users_just_left
      for user in @channel.users_just_left
        user.leaves_channel(@channel)
      end
    end
    
    # Do a clean up of users in the channel
    @channel.users.cleanup
    render :layout => false
  end
  
  def get_current_topic
    return false unless request.xhr?
    get_channel_and_channeltopic
    render :layout => false
  end
  
 
  private
  
  # Get channel and user info that most methods use
  def get_channel_and_user
    @user = User.find_by_id(session[:user_id])
    @channel = Channel.find_by_project_id(params[:id])
  end
  
  def get_channel
    @channel = Channel.find_by_project_id(params[:id])  
  end
  
  def get_channel_and_channeltopic
    @channel = Channel.find_by_project_id(params[:id])
    @channeltopic = ChannelTopic.find(@channel.topic_id)
  end
  
  def get_channel_title
    if (params[:id])
      @channel_title = Project.find_by_id(params[:id]).title
      #Project.find_by_id(params[:id]).title
     elsif (params[:title])
      @channel_title = params[:title]
    else
      @channel_title ="NO TITLE"
    end
  end
  
  def make_channel_name
    get_channel_title
    @channel_name = @channel_title.gsub(/[^\w\.]+/, '_')
  end
  
  def get_channel_topic(channel)
    if (params[:topic])
      @channel_topic = params[:topic]
    elsif(channel.topic_id>0)
      @channel_topic = ChannelTopic.find(channel.topic_id)
    else
      @channel_topic = channel.title+" Chat"
    end
  end
  
  def get_channelmessage_printout(channelmessage)
    if (channelmessage.level)
      @channelmessage_printout = %(> #{channelmessage.created_at.strftime('%R')} #{channelmessage.sender.profile.name}#{channelmessage.sender.profile_name_unique} #{channelmessage.content.gsub(/\n/,"    \n")}    \n\n)
    else
      @channelmessage_printout = %(#{channelmessage.created_at.strftime('%R')} #{channelmessage.sender.profile.name}#{channelmessage.sender.profile_name_unique}: #{channelmessage.content.gsub(/\n/,"    \n")}    \n\n)
    end
  end  
  
  def save_chat(filtercondition)
     get_channel
     #@user.say_in_channel(@channel, command+arguments)
     @channelmessages=@channel.latest_channelmessages(filtercondition)
     pagetitle=@channel.title+": Chat Log "+Time.now.to_s
     pagename=pagetitle.gsub(/[^\w\.]+/, '_')
	 #pagetext=make_small_title(pagetitle)
	 pagetext=" "
 	 for chanmessage in @channelmessages
 	    pagetext << get_channelmessage_printout(chanmessage)
     end
     Page.new(:name => pagename, :created_at => Time.now, :user_id => @user.id, :content => pagetext).save
   end
   
   def set_topic(arguments)
	  get_channel_and_user
	  @channeltopic=ChannelTopic.new(:title => arguments, :channel_id => @channel.id)
	  @channeltopic.save
	  @channel.topic_id=@channeltopic.id
      @channel.save;
      @user.topic_change_in_channel(@channel, arguments)
      @channelmessage = Channelmessage.find(:first, :order => "id DESC", :conditions => ["sender_id = ?", @user.id])
    end
end

