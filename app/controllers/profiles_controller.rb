class ProfilesController < ApplicationController
  before_filter :authorize, :except => [:index, :show]
  
  before_filter :find_current_user_profile, :only => [:edit, :update, :destroy]
  
  # GET /profiles
  # GET /profiles.xml
  def index
    @profiles = Profile.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @profiles.to_xml }
    end
  end

  # GET /users/1/profile
  # GET /users/1/profile.xml
  # GET /profiles/1
  # GET /profiles/1.xml
  def show
    begin
      if params[:user_id]
        @profile = User.find(params[:user_id]).profile
      else
        @profile = Profile.find(params[:id])
      end

      respond_to do |format|
        format.html # show.rhtml
        format.xml  { render :xml => @profile.to_xml }
      end
    rescue ActiveRecord::RecordNotFound
      error("Profile not found (id unknown)", "not found")
    end
  end

  # GET /users/1/profiles/new
  # GET /profiles/new
  def new
    unless current_user.profile
      @profile = Profile.new(:user_id => current_user.id)
    else
      error("Profile not created, maximum number of profiles per user exceeded", 
            "not created, maximum number of profiles per user exceeded")
    end
  end

  # GET /users/1/profile;edit
  # GET /profiles/1;edit
  def edit
    
  end

  # POST /profiles
  # POST /profiles.xml
  def create
    if (@profile = Profile.new(params[:profile]) unless current_user.profile)
      # set initial datetime
      @profile.created_at = @profile.updated_at = Time.now
  
      respond_to do |format|
        if @profile.save
          flash[:notice] = 'Profile was successfully created.'
          format.html { redirect_to profile_url(@profile) }
          format.xml  { head :created, :location => profile_url(@profile) }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @profile.errors.to_xml }
        end
      end
    else
      error("Profile not created, maximum number of profiles per user exceeded", 
            "not created, maximum number of profiles per user exceeded")
    end
  end

  # PUT /users/1/profile
  # PUT /users/1/profile.xml
  # PUT /profiles/1
  # PUT /profiles/1.xml
  def update
    # update datetime
    @profile.updated_at = Time.now

    respond_to do |format|
      if @profile.update_attributes(params[:profile])
        flash[:notice] = 'Profile was successfully updated.'
        format.html { redirect_to profile_url(@profile) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @profile.errors.to_xml }
      end
    end
  end

  # DELETE /users/1/profile
  # DELETE /users/1/profile.xml
  # DELETE /profiles/1
  # DELETE /profiles/1.xml
  def destroy
    @profile.destroy
  
    respond_to do |format|
      format.html { redirect_to profiles_url }
      format.xml  { head :ok }
    end
  end
  
protected
  
  def find_current_user_profile
    begin
      if params[:user_id]
        @profile = User.find(params[:user_id], :conditions => ["id = ?", current_user.id]).profile
      else
        @profile = Profile.find(params[:id], :conditions => ["user_id = ?", current_user.id])
      end
    rescue ActiveRecord::RecordNotFound
      error("Profile not found (id not authorized)", "is invalid (not owner)")
    end
  end
  
private
  
  def error(notice, message)
    flash[:notice] = notice
    (err = Profile.new.errors).add(:id, message)
    
    respond_to do |format|
      format.html { redirect_to profiles_url(current_user.id) }
      format.xml { render :xml => err.to_xml }
    end
  end
end
