class PostsController < ApplicationController
  before_filter :login_required
  
  before_filter :find_forum_and_topic_and_post,      :except => [:new, :index, :monitored, :search, :create]

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
    
    if params[:reply_id]
      # find original post
      found = Post.find_by_id_and_topic_id_and_forum_id(params[:reply_id], @topic, @forum)
      
      # append original post to reply
      @post.body = "bq. #{found.body}" + "<br />" + "\n\n" + @post.body
    end
    
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
  
  def new
    @post = Post.new
    
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
    
    # locate original message (being replied to)
    @original = Post.find_by_id_and_topic_id_and_forum_id(params[:reply_id], @topic, @topic.forum) if params[:reply_id]
  end
  
  def edit
    unless @post.editable_by? current_user
      flash[:notice] = "Error! Not authorized to edit post with ID #{params[:id]}"
      redirect_to :controller => :topics, :action => :show, :forum_id => @forum, :id => @topic
    else
      respond_to do |format| 
        format.html
        format.js
      end
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
      format.xml { head 200 }
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
      format.xml { head 200 }
    end
  end

protected
  def authorized?(forum=@forum, user=current_user)
    # forums_controller::authorized?
    forum.public or Moderatorship.find_by_forum_id_and_user_id(forum.id, current_user.id) or Membership.find_by_project_id_and_user_id(Project.find(forum.owner_id).id, current_user.id)
  end
  
  def find_forum
    if params[:forum_id]
      if project = Project.find_by_unique(params[:forum_id])
        @forum = Forum.find(project.forum_id)
      else
        begin
          @forum = Forum.find(params[:forum_id])
        rescue ActiveRecord::RecordNotFound
          @forum = nil
        end
      end
        
      if @forum
        unless authorized?
          @forum = nil
          flash[:notice] = "Error! Not authorized to view forum with ID #{params[:forum_id]}"
          redirect_to :controller => :forums
        end
      else
        flash[:notice] = "Error! Forum with ID #{params[:forum_id]} not found"
        redirect_to :controller => :forums
      end
    else
      flash[:notice] = "Error! No Forum ID suppled"
      redirect_to :controller => :forums
    end
  end
  
  def find_topic
    if params[:topic_id]
      unless @topic = Topic.find_by_id_and_forum_id(params[:topic_id], @forum.id)
        flash[:notice] = "Error! Topic with ID #{params[:topic_id]} not found"
        redirect_to :controller => :forums, :action => :show, :id => @forum.id
      end
    else
      flash[:notice] = "Error! No Topic ID suppled"
      redirect_to :controller => :forums
    end
  end
  
  def find_post
    if params[:id]
      unless @post = Post.find_by_id_and_topic_id_and_forum_id(params[:id], @topic.id, @forum.id)
        flash[:notice] = "Error! Post with ID #{params[:id]} not found"
        redirect_to :controller => :topics, :action => :show, :id => @topic.id
      end
    else
      flash[:notice] = "Error! No Post ID suppled"
      redirect_to :controller => :topics, :action => :show, :id => @topic.id
    end
  end
    
  def find_forum_and_topic_and_post
    find_forum
      
    find_topic if @forum
    
    find_post if @topic
  end
    
  def render_posts_or_xml(template_name = action_name)
    respond_to do |format|
      format.html { render :action => "#{template_name}.rhtml" }
      format.rss  { render :action => "#{template_name}.rxml", :layout => false }
      format.xml  { render :xml => @posts.to_xml }
    end
  end
  
end
