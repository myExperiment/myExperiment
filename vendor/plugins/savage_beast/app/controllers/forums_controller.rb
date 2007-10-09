class ForumsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  
  before_filter :find_forums, :only => [:index]
  before_filter :find_forum_auth, :only => [:edit, :show, :update, :destroy]

  helper :application
  
  def index
    respond_to do |format|
      format.html
      format.xml { render :xml => @forums.to_xml }
    end
  end

  def show
    @viewing = Viewing.create(:contribution => @forum.contribution, :user => (logged_in? ? current_user : nil))
    
    respond_to do |format|
      format.html do
        # keep track of when we last viewed this forum for activity indicators
        (session[:forums] ||= {})[@forum.id] = Time.now.utc if logged_in?
        @topic_pages, @topics = paginate(:topics, :per_page => 25, :conditions => ['forum_id = ?', params[:id]], :include => :replied_by_user, :order => 'sticky desc, replied_at desc')
      end
      
      format.xml do
        render :xml => @forum.to_xml
      end
    end
  end

  def new
    @forum = Forum.new
  end
  
  def edit
    
  end
  
  def create
    # hack for select contributor form
    if params[:contributor_pair]
      params[:forum][:contributor_type], params[:forum][:contributor_id] = "User", current_user.id                                       # forum contributed by current_user..
      params[:contribution][:contributor_type], params[:contribution][:contributor_id] = params[:contributor_pair][:class_id].split("-") # ..but owned by contributor_pair
      params.delete("contributor_pair")
    end
    
    @forum = Forum.new(params[:forum])
    
    respond_to do |format|
      if @forum.save
        # update policy
        @forum.contribution.update_attributes(params[:contribution])
        
        flash[:notice] = 'Forum was successfully created.'
        format.html { redirect_to forums_path }
        format.xml  { head :created, :location => formatted_forum_url(:id => @forum, :format => :xml) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @forum.errors.to_xml }
      end
    end
  end

  def update
    # hack for select contributor form
    if params[:contributor_pair]
      params[:contribution][:contributor_type], params[:contribution][:contributor_id] = params[:contributor_pair][:class_id].split("-")
      params.delete("contributor_pair")
    end
    
    # remove protected columns
    if params[:forum]
      [:contributor_id, :contributor_type, :topics_count, :posts_count].each do |column_name|
        params[:forum].delete(column_name)
      end
    end
    
    respond_to do |format|
      if @forum.update_attributes(params[:forum])
        # bug fix to not save 'default' workflow unless policy_id is selected
        @forum.contribution.policy = nil if (params[:contribution][:policy_id].nil? or params[:contribution][:policy_id].empty?)
        
        # security fix (only allow the owner to change the policy)
        @forum.contribution.update_attributes(params[:contribution]) if @forum.contribution.owner?(current_user)
        
        flash[:notice] = 'Forum was successfully updated.'
        format.html { redirect_to forums_path }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @forum.errors.to_xml }
      end
    end
  end
  
  def destroy
    @forum.destroy
    
    respond_to do |format|
      format.html { redirect_to forums_path }
      format.xml  { head :ok }
    end
  end
  
  protected
    def find_forums
      @forums = Forum.find(:all, :order => "position")
    end
  
    def find_forum_auth
      begin
        forum = Forum.find(params[:id])
        
        if forum.authorized?(action_name, (logged_in? ? current_user : nil))
          @forum = forum
        else
          if logged_in? 
            error("Forum not found (id not authorized)", "is invalid (not authorized)")
          else
            find_forum_auth if login_required
          end
        end
      rescue ActiveRecord::RecordNotFound
        error("Forum not found", "is invalid")
      end
    end

private

  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Forum.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to forums_path }
      format.xml { render :xml => err.to_xml }
    end
  end
end
