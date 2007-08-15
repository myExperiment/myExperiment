class PostsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  
  before_filter :find_forum_and_topic, :only => [:index, :search, :monitored, :create]
  before_filter :find_forum_and_topic_and_post, :except => [:index, :search, :monitored, :create]

  @@query_options = { :per_page => 25, :select => 'posts.*, topics.title as topic_title, forums.name as forum_name', :joins => 'inner join topics on posts.topic_id = topics.id inner join forums on topics.forum_id = forums.id', :order => 'posts.created_at desc' }

  def index
    conditions = []
    [:user_id, :forum_id].each { |attr| conditions << Post.send(:sanitize_sql, ["posts.#{attr} = ?", params[attr]]) if params[attr] }
    conditions = conditions.any? ? conditions.collect { |c| "(#{c})" }.join(' AND ') : nil
    @post_pages, @posts = paginate(:posts, @@query_options.merge(:conditions => conditions))
    @users = User.find(:all, :select => 'distinct *', :conditions => ['id in (?)', @posts.collect(&:user_id).uniq]).index_by(&:id)
    render_posts_or_xml
  end

  def search
    conditions = params[:q].blank? ? nilil : Post.send(:sanitize_sql, ['LOWER(posts.body) LIKE ?', "%#{params[:q]}%"])
    @post_pages, @posts = paginate(:posts, @@query_options.merge(:conditions => conditions))
    @users = User.find(:all, :select => 'distinct *', :conditions => ['id in (?)', @posts.collect(&:user_id).uniq]).index_by(&:id)
    render_posts_or_xml :index
  end

  def monitored
    @user = User.find params[:user_id]
    options = @@query_options.merge(:conditions => ['monitorships.user_id = ? and posts.user_id != ?', params[:user_id], @user.id])
    options[:joins] += ' inner join monitorships on monitorships.topic_id = topics.id'
    @post_pages, @posts = paginate(:posts, options)
    render_posts_or_xml
  end

  def show
    respond_to do |format|
      format.html { redirect_to topic_path(@post.forum_id, @post.topic_id) }
      format.xml  { render :xml => @post.to_xml }
    end
  end

  def create
    @topic = Topic.find_by_id_and_forum_id(params[:topic_id],params[:forum_id], :include => :forum)
    if @topic.locked?
      respond_to do |format|
        format.html do
          flash[:notice] = 'This topic is locked.'
          redirect_to(topic_path(:forum_id => params[:forum_id], :id => params[:topic_id]))
        end
        format.xml do
          render :text => 'This topic is locked.', :status => 400
        end
      end
      return
    end
    @forum = @topic.forum
    @post  = @topic.posts.build(params[:post])
    @post.user = current_user
    @post.save!
    respond_to do |format|
      format.html do
        redirect_to topic_path(:forum_id => params[:forum_id], :id => params[:topic_id], :anchor => @post.dom_id, :page => params[:page] || '1')
      end
      format.xml { head :created, :location => formatted_post_url(:forum_id => params[:forum_id], :topic_id => params[:topic_id], :id => @post, :format => :xml) }
    end
  rescue ActiveRecord::RecordInvalid
    flash[:bad_reply] = 'Please post something at least...'
    respond_to do |format|
      format.html do
        redirect_to topic_path(:forum_id => params[:forum_id], :id => params[:topic_id], :anchor => 'reply-form', :page => params[:page] || '1')
      end
      format.xml { render :xml => @post.errors.to_xml, :status => 400 }
    end
  end
  
  def edit
    respond_to do |format| 
      format.html
      format.js
    end
  end
  
  def update
    @post.attributes = params[:post]
    @post.save!
  rescue ActiveRecord::RecordInvalid
    flash[:bad_reply] = 'An error occurred'
  ensure
    respond_to do |format|
      format.html do
        redirect_to topic_path(:forum_id => params[:forum_id], :id => params[:topic_id], :anchor => @post.dom_id, :page => params[:page] || '1')
      end
      format.js
      format.xml { head :ok }
    end
  end

  def destroy
    @post.destroy
    flash[:notice] = "Post of '#{CGI::escapeHTML @post.topic.title}' was deleted."
    # check for posts_count == 1 because its cached and counting the currently deleted post
    @post.topic.destroy and redirect_to forum_path(params[:forum_id]) if @post.topic.posts_count == 1
    respond_to do |format|
      format.html do
        redirect_to topic_path(:forum_id => params[:forum_id], :id => params[:topic_id], :page => params[:page]) unless performed?
      end
      format.xml { head :ok }
    end
  end

protected
  def find_forum_auth
    if params[:forum_id]
      begin
        forum = Forum.find(params[:forum_id])
        
        if forum.authorized?("show", (logged_in? ? current_user : nil)) # the forum authorization is always "show" ('in forum' editing is handled separately)
          @forum = forum
        else
          error("Forum not found (id not authorized)", "is invalid (not authorized)", :forum_id)
        end
      rescue ActiveRecord::RecordNotFound
        error("Forum not found", "is invalid", :forum_id)
      end
    else
      error("Please supply a Forum ID", "is invalid", :forum_id)
    end
  end
  
  def find_topic
    if params[:topic_id]
      begin
        @topic = @forum.topics.find(params[:topic_id])
      rescue ActiveRecord::RecordNotFound
        error("Topic not found (id invalid)", "is invalid", :topic_id)
      end
    else
      error("Please supply a Topic ID", "is invalid", :topic_id)
    end
  end
  
  def find_post
    if params[:id]
      begin
        post = @topic.posts.find(params[:id])
        
        if action_name == 'show' || post.editable_by?(current_user)
          @post = post
        else
          error("Post not found (id not authorized)", "is invalid (not authorized)")
        end
      rescue ActiveRecord::RecordNotFound
        error("Post not found (id invalid)", "is invalid")
      end
    else
      error("Please supply a Post ID", "is invalid")
    end
    
    #@post = Post.find_by_id_and_topic_id_and_forum_id(params[:id], params[:topic_id], params[:forum_id]) || raise(ActiveRecord::RecordNotFound)
  end
  
  def find_forum_and_topic
    find_forum_auth
    
    find_topic if @forum
  end
    
  def find_forum_and_topic_and_post
    find_forum_and_topic
    
    find_post if @topic
  end
    
  def render_posts_or_xml(template_name = action_name)
    respond_to do |format|
      format.html { render :action => "#{template_name}.rhtml" }
      format.rss  { render :action => "#{template_name}.rxml", :layout => false }
      format.xml  { render :xml => @posts.to_xml }
    end
  end
  
private

  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Post.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to forums_path }
      format.xml { render :xml => err.to_xml }
    end
  end
end
