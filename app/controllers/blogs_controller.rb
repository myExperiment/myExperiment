# myExperiment: app/controllers/blogs_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class BlogsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  
  before_filter :find_blogs, :only => [:index]
  #before_filter :find_blog_auth, :only => [:show, :edit, :update, :destroy]
  before_filter :find_blog_auth, :except => [:index, :new, :create, :update, :destroy]
  
  # GET /blogs
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # GET /blogs/1
  def show
    @viewing = Viewing.create(:contribution => @blog.contribution, :user => (logged_in? ? current_user : nil))
    
    @sharing_mode  = @blog.contribution.policy.share_mode
    
    respond_to do |format|
      format.html # show.rhtml
    end
  end

  # GET /blogs/new
  def new
    @blog = Blog.new

    @sharing_mode  = 0
  end

  # GET /blogs/1;edit
  def edit
    @sharing_mode  = @blog.contribution.policy.share_mode
  end

  # POST /blogs
  def create

    return error('Creating new blog content is disabled', 'is disabled')

    params[:blog][:contributor_type] = "User"
    params[:blog][:contributor_id]   = current_user.id
    
    @blog = Blog.new(params[:blog])
    
    respond_to do |format|
      if @blog.save

        @blog.contribution.update_attributes(params[:contribution])

        update_policy(@blog, params)
        
        flash[:notice] = 'Blog was successfully created.'
        format.html { redirect_to blog_url(@blog) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /blogs/1
  def update
    
    # remove protected columns
    if params[:blog]
      [:contributor_id, :contributor_type, :created_at, :updated_at].each do |column_name|
        params[:blog].delete(column_name)
      end
    end
    
    respond_to do |format|
      if @blog.update_attributes(params[:blog])
        
        # security fix (only allow the owner to change the policy)
        @blog.contribution.update_attributes(params[:contribution]) if @blog.contribution.owner?(current_user)
        
        update_policy(@blog, params)

        flash[:notice] = 'Blog was successfully updated.'
        format.html { redirect_to blog_url(@blog) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /blogs/1
  def destroy
    @blog.destroy

    respond_to do |format|
      format.html { redirect_to blogs_url }
    end
  end
  
protected

  def find_blogs
    @blogs = Blog.find(:all, 
                       :order => "title ASC, created_at DESC",
                       :page => { :size => 20, 
                                  :current => params[:page] })
  end
  
  def find_blog_auth
    begin
      blog = Blog.find(params[:id])
      
      if Authorization.is_authorized?(action_name, nil, blog, current_user)
        @blog = blog
      else
        if logged_in? 
          error("Blog not found (id not authorized)", "is invalid (not authorized)")
        else
          find_blog_auth if login_required
        end
      end
    rescue ActiveRecord::RecordNotFound
      error("Blog not found", "is invalid")
    end
  end
  
private

  def error(notice, message, attr=:id)
    flash[:error] = notice
    (err = Blog.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to blogs_url }
    end
  end
end
