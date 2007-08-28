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

class MessagesController < ApplicationController

   before_filter :login_required

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :show ], :redirect_to => { :action => :list }

  def index
    redirect_to :action => 'list'
  end

  def new
    @person = User.find(params[:id]) if params[:id]
  end

  def reply
    original_message = Message.find_by_id_and_to_id(params[:id], session[:user_id])
    if original_message
      @message = Message.new()
      if original_message.reply_id
        @message.subject = original_message.subject
      else
        @message.subject = 'Re: ' + original_message.subject
      end
      @message.reply_id = original_message.id
      @person = User.find(original_message.from_id)
      render :action => 'new'
    else
      flash[:notice] = 'Message not found'
      redirect_to :action => 'list'
    end
  end

  def create
    @message = Message.new(params[:message])
    @message.from_id = session[:user_id]
    @message.to_id = params[:id]
    @message.subject = 'no subject' if not @message.subject or @message.subject == ''
    if @message.save
      flash[:notice] = 'Message was successfully sent.'
      redirect_to :action => 'list'
    else
      flash[:notice] = 'Failed to send message.'
      render :action => 'new'
    end
   end

  def show
    @message = Message.find_by_id_and_to_id(params[:id], session[:user_id])
    if @message
      @message.read!
      @from = User.find(@message.from_id)
    else
      flash[:notice] = 'Message not found'
      redirect_to :action => 'list'
    end
  end

  def destroy
    if params[:message]
      for message in params[:message]
        Message.find(message).destroy
      end
    end
    redirect_to :action => 'list'
  end

  def list
    @messages = Message.find(:all, :conditions => ["to_id = ?", session[:user_id]],
                             :order => 'created_at DESC',
                             :page => {:size => 10, :current => params[:page], :first => 1})
  end

end
