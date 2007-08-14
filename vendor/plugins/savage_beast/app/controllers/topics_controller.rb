class TopicsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  
  before_filter :find_forum_auth, :only => [:index, :new, :create]
  before_filter :find_forum_and_topic, :except => [:index, :new, :create]
  
  before_filter :update_last_seen_at, :only => [:show]

  def index
    respond_to do |format|
      format.html { redirect_to forum_path(params[:forum_id]) }
      format.xml do
        @topics = Topic.find_all_by_forum_id(params[:forum_id], :order => 'sticky desc, replied_at desc', :limit => 25)
        render :xml => @topics.to_xml
      end
    end
  end

  def new
    @topic = Topic.new
  end
  
  def show
    respond_to do |format|
      format.html do
        # see notes in application.rb on how this works
        update_last_seen_at
        # keep track of when we last viewed this topic for activity indicators
        (session[:topics] ||= {})[@topic.id] = Time.now.utc if logged_in?
        # authors of topics don't get counted towards total hits
        @topic.hit! unless logged_in? and @topic.user == current_user
        @post_pages, @posts = paginate(:posts, :per_page => 25, :order => 'posts.created_at', :include => :user, :conditions => ['posts.topic_id = ?', params[:id]])
        @voices = @posts.map(&:user) ; @voices.uniq!
        @post   = Post.new
      end
      format.xml do
        render :xml => @topic.to_xml
      end
      format.rss do
        @posts = @topic.posts.find(:all, :order => 'created_at desc', :limit => 25)
        render :action => 'show.rxml', :layout => false
      end
    end
  end
  
  def create
    # this is icky - move the topic/first post workings into the topic model?
    Topic.transaction do
      @topic  = @forum.topics.build(params[:topic])
      assign_protected
      @post   = @topic.posts.build(params[:topic])
      @post.topic=@topic
      @post.user = current_user
      # only save topic if post is valid so in the view topic will be a new record if there was an error
      @topic.save! if @post.valid?
      @post.save! 
    end
    respond_to do |format|
      format.html { redirect_to topic_path(@forum, @topic) }
      format.xml  { head :created, :location => formatted_topic_url(:forum_id => @forum, :id => @topic, :format => :xml) }
    end
  end
  
  def update
    @topic.attributes = params[:topic]
    assign_protected
    @topic.save!
    respond_to do |format|
      format.html { redirect_to topic_path(@forum, @topic) }
      format.xml  { head :ok }
    end
  end
  
  def destroy
    @topic.destroy
    flash[:notice] = "Topic '#{CGI::escapeHTML @topic.title}' was deleted."
    respond_to do |format|
      format.html { redirect_to forum_path(@forum) }
      format.xml  { head :ok }
    end
  end
  
protected
  
  def assign_protected
    @topic.user     = current_user if @topic.new_record?
    # admins and moderators can sticky and lock topics
    return unless admin? or current_user.moderator_of?(@topic.forum)
    @topic.sticky, @topic.locked = params[:topic][:sticky], params[:topic][:locked] 
    # only admins can move
    return unless admin?
    @topic.forum_id = params[:topic][:forum_id] if params[:topic][:forum_id]
  end
    
  def find_forum_auth
    if params[:forum_id]
      begin
        forum = Forum.find(params[:forum_id])
        
        if forum.authorized?(action_name, (logged_in? ? current_user : nil))
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
    if params[:id]
      begin
        @topic = @forum.topics.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        error("Topic not found (id invalid)", "is invalid")
      end
    else
      error("Please supply a Topic ID", "is invalid")
    end
  end
    
  def find_forum_and_topic
    find_forum_auth
    
    find_topic if @forum
  end
    
private

  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Topic.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to forums_path }
      format.xml { render :xml => err.to_xml }
    end
  end
end
