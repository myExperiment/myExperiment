class BlogsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  
  before_filter :find_blogs, :only => [:index]
  #before_filter :find_blog_auth, :only => [:show, :edit, :update, :destroy]
  before_filter :find_blog_auth, :except => [:index, :new, :create]
  
  # GET /blogs
  # GET /blogs.xml
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @blogs.to_xml }
    end
  end

  # GET /blogs/1
  # GET /blogs/1.xml
  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @blog.to_xml }
    end
  end

  # GET /blogs/new
  def new
    @blog = Blog.new
  end

  # GET /blogs/1;edit
  def edit

  end

  # POST /blogs
  # POST /blogs.xml
  def create
    # hack for select contributor form
    if params[:contributor_pair]
      params[:blog][:contributor_type], params[:blog][:contributor_id] = params[:contributor_pair][:class_id].split("-")
      params.delete("contributor_pair")
    end
    
    @blog = Blog.new(params[:blog])

    respond_to do |format|
      if @blog.save
        # if the user selects a different contributor_pair
        # --> @contributable.contributor = params[:contributor_pair]
        #     @contributable.contribution.contributor = current_user
        @blog.update_attribute(:contributor_id, current_user.id) if @blog.contribution.contributor_id.to_i != current_user.id.to_i
        @blog.update_attribute(:contributor_type, current_user.class.to_s) if @blog.contribution.contributor_type.to_s != current_user.class.to_s
        
        @blog.contribution.update_attributes(params[:contribution])
        
        flash[:notice] = 'Blog was successfully created.'
        format.html { redirect_to blog_url(@blog) }
        format.xml  { head :created, :location => blog_url(@blog) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @blog.errors.to_xml }
      end
    end
  end

  # PUT /blogs/1
  # PUT /blogs/1.xml
  def update
    respond_to do |format|
      if @blog.update_attributes(params[:blog])
        # security fix (only allow the owner to change the policy)
        @blog.contribution.update_attributes(params[:contribution]) if @blog.contribution.owner?(current_user)
        
        flash[:notice] = 'Blog was successfully updated.'
        format.html { redirect_to blog_url(@blog) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @blog.errors.to_xml }
      end
    end
  end

  # DELETE /blogs/1
  # DELETE /blogs/1.xml
  def destroy
    @blog.destroy

    respond_to do |format|
      format.html { redirect_to blogs_url }
      format.xml  { head :ok }
    end
  end
  
protected

  def find_blogs
    @blogs = Blog.find(:all, :order => "created_at DESC")
  end
  
  def find_blog_auth
    begin
      blog = Blog.find(params[:id])
      
      if blog.authorized?(action_name, (logged_in? ? current_user : nil))
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
    flash[:notice] = notice
    (err = Blog.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to blogs_url }
      format.xml { render :xml => err.to_xml }
    end
  end
end
