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

class BlogPostsController < ApplicationController
  before_filter :login_required
  
  before_filter :find_blog_and_blog_posts, :only => [:index]
  before_filter :find_blog_and_blog_post, :only => [:show, :edit, :update, :destroy]
  before_filter :find_blog_auth, :only => [:new]
  
  # GET /blog_posts
  # GET /blog_posts.xml
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @blog_posts.to_xml }
    end
  end

  # GET /blog_posts/1
  # GET /blog_posts/1.xml
  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @blog_post.to_xml }
    end
  end

  # GET /blog_posts/new
  def new
    @blog_post = BlogPost.new(:blog => @blog)
  end

  # GET /blog_posts/1;edit
  def edit

  end

  # POST /blog_posts
  # POST /blog_posts.xml
  def create
    @blog_post = BlogPost.new(params[:blog_post])

    respond_to do |format|
      if @blog_post.save
        flash[:notice] = 'BlogPost was successfully created.'
        format.html { redirect_to blog_url(@blog_post.blog) }
        format.xml  { head :created, :location => blog_url(@blog_post.blog) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @blog_post.errors.to_xml }
      end
    end
  end

  # PUT /blog_posts/1
  # PUT /blog_posts/1.xml
  def update
    respond_to do |format|
      if @blog_post.update_attributes(params[:blog_post])
        flash[:notice] = 'BlogPost was successfully updated.'
        format.html { redirect_to blog_url(@blog_post.blog) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @blog_post.errors.to_xml }
      end
    end
  end

  # DELETE /blog_posts/1
  # DELETE /blog_posts/1.xml
  def destroy
    @blog_post.destroy

    respond_to do |format|
      format.html { redirect_to blog_url(@blog_post.blog) }
      format.xml  { head :ok }
    end
  end
  
protected

  def find_blog_auth
    begin
      blog = Blog.find(params[:blog_id])
      
      if blog.authorized?(action_name, (logged_in? ? current_user : nil))
        @blog = blog
      else
        error("Blog not found (id not authorized)", "is invalid (not authorized)")
      end
    rescue ActiveRecord::RecordNotFound
      error("Blog not found", "is invalid")
    end
  end
  
  def find_blog_posts
    options = { :order => "created_at DESC" }
    options = options.merge({ :conditions => ["blog_id = ?", @blog.id] }) if @blog
    
    @blog_posts = BlogPost.find(:all, options)
  end
  
  def find_blog_post
    begin
      @blog_post = BlogPost.find(params[:id], :conditions => ["blog_id = ?", @blog.id])
    rescue ActiveRecord::RecordNotFound
      error("Blog Post not found", "is invalid")
    end
  end
  
  def find_blog_and_blog_posts
    find_blog_auth
    
    find_blog_posts if @blog
  end
  
  def find_blog_and_blog_post
    find_blog_auth
    
    find_blog_post if @blog
  end
  
private

  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = BlogPost.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to blog_posts_url(params[:blog_id]) }
      format.xml { render :xml => err.to_xml }
    end
  end
end
