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

class RepliesController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @reply_pages, @replies = paginate :replies, :per_page => 10
  end

  def show
    @reply = Reply.find(params[:id])
  end

  def new
    @reply = Reply.new
  end

  def create
    @reply = Reply.new(params[:reply])
    if @reply.save
      flash[:notice] = 'Reply was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @reply = Reply.find(params[:id])
  end

  def update
    @reply = Reply.find(params[:id])
    if @reply.update_attributes(params[:reply])
      flash[:notice] = 'Reply was successfully updated.'
      redirect_to :action => 'show', :id => @reply
    else
      render :action => 'edit'
    end
  end

  def destroy
    Reply.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
