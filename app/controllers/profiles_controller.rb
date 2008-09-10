# myExperiment: app/controllers/profiles_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class ProfilesController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  
  before_filter :find_profiles, :only => [:index]
  before_filter :find_profile, :only => [:show]
  before_filter :find_profile_auth, :only => [:edit, :update, :destroy]
  
  before_filter :invalidate_listing_cache, :only => [:update, :destroy]

  # declare sweepers and which actions should invoke them
  cache_sweeper :profile_sweeper, :only => [ :create, :update, :destroy ]
  
  # GET /profiles
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # GET /users/1/profile
  # GET /profiles/1
  def show
    respond_to do |format|
      format.html # show.rhtml
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
  def create
    if (@profile = Profile.new(params[:profile]) unless current_user.profile)
      # set legal value for "null avatar"
      (@profile.picture_id = nil) if (@profile.picture_id.to_i == 0)
      
      respond_to do |format|
        if @profile.save
          flash[:notice] = 'Profile was successfully created.'
          format.html { redirect_to profile_url(@profile) }
        else
          format.html { render :action => "new" }
        end
      end
    else
      error("Profile not created, maximum number of profiles per user exceeded", 
            "not created, maximum number of profiles per user exceeded")
    end
  end

  # PUT /users/1/profile
  # PUT /profiles/1
  def update
    # maintain legal value for "null avatar"
    (params[:profile][:picture_id] = nil) if (params[:profile][:picture_id].to_i == 0)
    
    respond_to do |format|
      if @profile.update_attributes(params[:profile])
        flash[:notice] = 'Profile was successfully updated.'
        #format.html { redirect_to profile_url(@profile) }
        format.html { redirect_to user_path(@profile.owner) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /users/1/profile
  # DELETE /profiles/1
  def destroy
    @profile.destroy
  
    respond_to do |format|
      format.html { redirect_to profiles_url }
    end
  end
  
protected

  def find_profiles
    @profiles = Profile.find(:all, 
                             :include => :owner, 
                             :order => "users.name ASC",
                             :page => { :size => 20, 
                                        :current => params[:page] })
  end

  def find_profile
    begin
      if params[:user_id]
        begin
          @user = User.find(params[:user_id])
          @profile = @user.profile
        rescue ActiveRecord::RecordNotFound
          error("User not found (id unknown)", "not found", attr=:user_id)
        end
      else
        @profile = Profile.find(params[:id])
        @user = @profile.owner
      end
    rescue ActiveRecord::RecordNotFound
      error("Profile not found (id unknown)", "not found")
    end
  end
  
  def find_profile_auth
    begin
      if params[:user_id]
        begin
          @user = User.find(params[:user_id], :conditions => ["id = ?", current_user.id])
          @profile = @user.profile
        rescue ActiveRecord::RecordNotFound
          error("User not found (id unknown)", "not found", attr=:user_id)
        end
      else
        @profile = Profile.find(params[:id], :conditions => ["user_id = ?", current_user.id])
        @user = @profile.owner
      end
    rescue ActiveRecord::RecordNotFound
      error("Profile not found (id not authorized)", "is invalid (not owner)")
    end
  end
  
  def invalidate_listing_cache
    if @profile
      expire_fragment(:controller => 'users_cache', :action => 'listing', :id => @profile.user_id)
    end
  end
  
private

  def error(notice, message, attr=:id)
    flash[:error] = notice
    (err = Profile.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to profile_url(profile.id) }
    end
  end
end
