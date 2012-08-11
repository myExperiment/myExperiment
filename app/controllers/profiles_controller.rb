# myExperiment: app/controllers/profiles_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class ProfilesController < ApplicationController

  before_filter :login_required, :except => [:index, :show]

  before_filter :find_profiles, :only => [:index]
  before_filter :find_profile, :except => [:index]
  before_filter :auth, :except => [:index, :show]
  
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
      flash[:error] = "Profile not created, maximum number of profiles per user exceeded"
      respond_to do |format|
        format.html { redirect_to profile_url(@profile) }
      end
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
          format.html { redirect_to user_profile_url(@profile) }
        else
          format.html { render :action => "new" }
        end
      end
    else
      flash[:error] = "Profile not created, maximum number of profiles per user exceeded"
      respond_to do |format|
        format.html { redirect_to profile_url(@profile) }
      end
    end
  end

  # PUT /users/1/profile
  # PUT /profiles/1
  def update
    # maintain legal value for "null avatar"
    (params[:profile][:picture_id] = nil) if (params[:profile][:picture_id].to_i == 0)
    
    raise "Cannot update profile until user is activated" unless @profile.owner.activated_at

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
      @user = User.find(params[:user_id])
      @profile = @user.profile
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "User not found"
      respond_to do |format|
        format.html { redirect_to users_url }
      end
    end
  end
  
  def auth
    if current_user != @user
      flash[:error] = "You are not authorized to perform this action"
      respond_to do |format|
        format.html { redirect_to profile_url(@profile) }
      end
    end
  end

end
