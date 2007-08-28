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

class BlogController < ApplicationController

  before_filter :login_required #, :except => [:list, :index, :show]

  def index
    @recent = Blog.find(:all, :order => "created_at DESC", :limit => 10)
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list

    @this_id = params[:id];

    if (@this_id == nil)
      @this_id = session[:user_id]
    end

    @user_blogs = Blog.find(:all, :conditions => ["user_id = ?", @this_id],
                             :order => 'created_at DESC')

    @blog_pages, @blogs = paginate_collection @user_blogs, :page => @params[:page]

    @my_blog = @this_id == session[:user_id]

    @person = User.find(@this_id)
    @profile = @person.profile
    @name = @profile.name

  end

  def show
    @blog = Blog.find(params[:id])
  end

  def new
    @blog = Blog.new
  end

  def create

    @blog = Blog.new(params[:blog])

    @blog.user_id = session[:user_id]

    if @blog.save
      flash[:notice] = 'Blog post was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @blog = Blog.find(params[:id])
  end

  def update
    @blog = Blog.find(params[:id])
    if @blog.update_attributes(params[:blog])
      flash[:notice] = 'Blog post was successfully updated.'
      redirect_to :action => 'show', :id => @blog
    else
      render :action => 'edit'
    end
  end

  def comment
    @blog = Blog.find(params[:id])
    @comment = Comment.new(:comment => params[:comment], :user_id => session[:user_id])
    @blog.add_comment @comment
    render :partial => 'workflow/comment'
  end

  def destroy
    Blog.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
