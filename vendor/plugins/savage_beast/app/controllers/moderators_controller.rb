class ModeratorsController < ApplicationController
  before_filter :login_required
  
  before_filter :find_forum_auth, :only => [:index, :new, :create]
  before_filter :find_forum_and_moderatorship, :only => [:show, :destroy]
  
  def index
    @moderatorships = @forum.moderatorships
  end
  
  def show
    
  end
  
  def new
    @moderatorship = Moderatorship.new
  end
  
  def create
    @moderatorship = Moderatorship.new(params[:moderatorship].merge({:forum_id => @forum}))
    
    respond_to do |format|
      if @moderatorship.save
        format.html { redirect_to moderatorships_path(@forum) }
#       format.xml  { head :ok }
      else
        format.html { render :action => "new" }
#       format.xml { render :xml => @moderatorship.errors.to_xml }
      end
    end
  end
  
  def destroy
    @moderatorship.destroy

    respond_to do |format|
      format.html { redirect_to moderatorships_path(@forum) }
#     format.xml  { head :ok }
    end
  end

protected

  def find_forum_auth
    if params[:forum_id]
      begin
        forum = Forum.find(params[:forum_id])
        
        if forum.authorized?("destroy", current_user) # only the forum owner is allowed to add/remove moderators
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
  
  def find_moderatorship
    if params[:id]
      begin
        if moderatorship = @forum.moderatorships.find(params[:id])
          @moderatorship = moderatorship
        else
          error("Moderatorship not found (id not authorized)", "is invalid (not authorized)")
        end
      rescue ActiveRecord::RecordNotFound
        error("Moderatorship not found", "is invalid")
      end
    else
      error("Please supply a Moderatorship ID", "is invalid")
    end
  end

  def find_forum_and_moderatorship
    find_forum_auth
    
    find_moderatorship if @forum
  end
  
private

  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Moderatorship.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to moderators_url }
#     format.xml { render :xml => err.to_xml }
    end
  end
end
