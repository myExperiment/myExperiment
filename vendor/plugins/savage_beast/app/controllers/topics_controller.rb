class TopicsController < ApplicationController
  before_filter :login_required
  
  before_filter :find_forum_and_topic, :except => :index
  
  before_filter :find_forum, :only => :index
  
  before_filter :update_last_seen_at, :only => :show
  
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
  
  def edit
    unless @topic.editable_by? current_user
      flash[:notice] = "Error! Not authorized to edit topic with ID #{params[:id]}"
      redirect_to :action => :show, :forum_id => @forum, :id => @topic
    end
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
      format.xml  { head 200 }
    end
  end
  
  def destroy
    @topic.destroy
    flash[:notice] = "Topic '#{CGI::escapeHTML @topic.title}' was deleted."
    respond_to do |format|
      format.html { redirect_to forum_path(@forum) }
      format.xml  { head 200 }
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
    
  def authorized?(forum=@forum)
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
    if params[:id]
      unless @topic = Topic.find_by_id_and_forum_id(params[:id], @forum.id)
        flash[:notice] = "Error! Topic with ID #{params[:id]} not found"
        redirect_to :controller => :forums, :action => :show, :id => @forum.id
      end
    else
      flash[:notice] = "Error! No Topic ID suppled"
      redirect_to :controller => :forums
    end
  end
    
  def find_forum_and_topic
    find_forum
      
    find_topic if @forum
  end
  
end
