class ForumsController < ApplicationController
  before_filter :login_required
  
  before_filter :find_forum, :except => :index
  
  before_filter :find_authorized_forums, :only => :index

  helper :application
  
  def index
    respond_to do |format|
      format.html
      format.xml { render :xml => @forums.to_xml }
    end
  end
  
  def edit 
    unless Moderatorship.find_by_forum_id_and_user_id(@forum, current_user.id)
      flash[:notice] = "Error! Not authorized to edit forum with ID #{params[:id]}"
      redirect_to :action => :show, :id => params[:id]
    end
  end

  def show
    respond_to do |format|
      format.html do
        # keep track of when we last viewed this forum for activity indicators
        (session[:forums] ||= {})[@forum.id] = Time.now.utc if logged_in?
        @topic_pages, @topics = paginate(:topics, :per_page => 25, :conditions => ['forum_id = ?', @forum.id], :include => :replied_by_user, :order => 'sticky desc, replied_at desc')
      end
      
      format.xml do
        render :xml => @forum.to_xml
      end
    end
  end

  # new renders new.rhtml
  
  def create
    @forum.attributes = params[:forum]
    @forum.save!
    respond_to do |format|
      format.html { redirect_to forums_path }
      format.xml  { head :created, :location => formatted_forum_url(:id => @forum, :format => :xml) }
    end
  end

  def update
    @forum.attributes = params[:forum]
    @forum.save!
    respond_to do |format|
      format.html { redirect_to forums_path }
      format.xml  { head 200 }
    end
  end
  
  def destroy
    @forum.destroy
    respond_to do |format|
      format.html { redirect_to forums_path }
      format.xml  { head 200 }
    end
  end
  
protected
  def authorized?(forum=@forum)
    forum.public or Moderatorship.find_by_forum_id_and_user_id(forum.id, current_user.id) or Membership.find_by_project_id_and_user_id(Project.find(forum.owner_id).id, current_user.id)
  end
    
  def find_authorized_forums
    @forums = []
    Forum.find(:all).each do |forum|
      @forums << forum if authorized? forum
    end
  end
    
  def find_forum
    if params[:id]
      if project = Project.find_by_unique(params[:id])
        @forum = Forum.find(project.forum_id)
      else
        begin
          @forum = Forum.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          @forum = nil
        end
      end
        
      if @forum
        unless authorized?
          @forum = nil
          flash[:notice] = "Error! Not authorized to view forum with ID #{params[:id]}"
          redirect_to :action => :index
        end
      else
        flash[:notice] = "Error! Forum with ID #{params[:id]} not found"
        redirect_to :action => :index
      end
    else
      flash[:notice] = "Error! No Forum ID suppled"
      redirect_to :action => :index
    end
  end
  
end
