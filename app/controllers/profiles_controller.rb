class ProfilesController < ApplicationController
  before_filter :authorize, :except => [:index, :show]
  
  verify :method => :get, :only => [:index, :show, :new, :edit],
         :redirect_to => { :action => :index }
         
  verify :method => :put, :only => [:update],
         :redirect_to => { :action => :index }
         
  verify :method => :delete, :only => [:destroy],
         :redirect_to => { :action => :index }
  
  # GET /profiles
  # GET /profiles.xml
  def index
    @profiles = Profile.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @profiles.to_xml }
    end
  end

  # GET /profiles/1
  # GET /profiles/1.xml
  def show
    begin
      @profile = Profile.find(params[:id])

      respond_to do |format|
        format.html # show.rhtml
        format.xml  { render :xml => @profile.to_xml }
      end
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "Profile not found (id unknown)"
      (@profile = Profile.new).errors.add(:id, "not found")
      
      respond_to do |format|
        format.html { redirect_to profiles_url }
        format.xml { render @profile.errors.to_xml }
      end
    end
  end

  # GET /profiles/new
  def new
    unless (@profile = Profile.new(:user_id => current_user.id) unless Profile.find_by_user_id(current_user.id))
      flash[:notice] = "Profile not created, maximum number of profiles per user exceeded"
      (@profile = Profile.new).errors.add(:id, "not created, maximum number of profiles per user exceeded")
      
      respond_to do |format|
        format.html { redirect_to profiles_url }
        format.xml { render @profile.errors.to_xml }
      end
    end
  end

  # GET /profiles/1;edit
  def edit
    begin
      @profile = Profile.find(params[:id], :conditions => ["user_id = ?", current_user.id])
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "Profile not found (id not authorized)"
      (@profile = Profile.new).errors.add(:id, "is invalid (not owner)")
    
      respond_to do |format|
        format.html { redirect_to profiles_url }
        format.xml { render :xml => @profile.errors.to_xml }
      end
    end
  end

  # POST /profiles
  # POST /profiles.xml
  def create
    if (@profile = Profile.new(params[:profile]) unless Profile.find_by_user_id(current_user.id))
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
      flash[:notice] = "Profile not created, maximum number of profiles per user exceeded"
      (@profile = Profile.new).errors.add(:id, "not created, maximum number of profiles per user exceeded")
      
      respond_to do |format|
        format.html { redirect_to profiles_url }
        format.xml { render @profile.errors.to_xml }
      end
    end
    
  end

  # PUT /profiles/1
  # PUT /profiles/1.xml
  def update
    begin
      @profile = Profile.find(params[:id], :conditions => ["user_id = ?", current_user.id])
    
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
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "Profile not found (id not authorized)"
      (@profile = Profile.new).errors.add(:id, "is invalid (not owner)")
    
      respond_to do |format|
        format.html { redirect_to profiles_url }
        format.xml { render :xml => @profile.errors.to_xml }
      end
    end
  end

  # DELETE /profiles/1
  # DELETE /profiles/1.xml
  def destroy
    begin
      @profile = Profile.find(params[:id], :conditions => ["user_id = ?", current_user.id])
      @profile.destroy
  
      respond_to do |format|
        format.html { redirect_to profiles_url }
        format.xml  { head :ok }
      end
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "Profile not found (id not authorized)"
      (@profile = Profile.new).errors.add(:id, "is invalid (not owner)")
    
      respond_to do |format|
        format.html { redirect_to profiles_url }
        format.xml { render :xml => @profile.errors.to_xml }
      end
    end
  end
end
