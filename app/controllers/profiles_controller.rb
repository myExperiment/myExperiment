##
##
## myExperiment - a social network for scientists
##
## Copyright (C) 2007 University of Manchester/University of Southampton
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License
## as published by the Free Software Foundation; either version 3 of the
## License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program; if not, see http://www.gnu.org/licenses
## or write to the Free Software Foundation,Inc., 51 Franklin Street,
## Fifth Floor, Boston, MA 02110-1301  USA
##
##

class ProfilesController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  
  before_filter :find_profiles, :only => [:index]
  before_filter :find_profile, :only => [:show]
  before_filter :find_profile_auth, :only => [:edit, :update, :destroy]
  
  # GET /profiles
  # GET /profiles.xml
  def index
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
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @profile.to_xml }
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
      # set legal value for "null avatar"
      (@profile.picture_id = nil) if (@profile.picture_id.to_i == 0)
      
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
    # maintain legal value for "null avatar"
    (params[:profile][:picture_id] = nil) if (params[:profile][:picture_id].to_i == 0)
    
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

  def find_profiles
    @profiles = Profile.find(:all, 
                             :order => "created_at DESC",
                             :page => { :size => 20, 
                                        :current => params[:page] })
  end

  def find_profile
    begin
      if params[:user_id]
        begin
          @profile = User.find(params[:user_id]).profile
        rescue ActiveRecord::RecordNotFound
          error("User not found (id unknown)", "not found", attr=:user_id)
        end
      else
        @profile = Profile.find(params[:id])
      end
    rescue ActiveRecord::RecordNotFound
      error("Profile not found (id unknown)", "not found")
    end
  end
  
  def find_profile_auth
    begin
      if params[:user_id]
        begin
          @profile = User.find(params[:user_id], :conditions => ["id = ?", current_user.id]).profile
        rescue ActiveRecord::RecordNotFound
          error("User not found (id unknown)", "not found", attr=:user_id)
        end
      else
        @profile = Profile.find(params[:id], :conditions => ["user_id = ?", current_user.id])
      end
    rescue ActiveRecord::RecordNotFound
      error("Profile not found (id not authorized)", "is invalid (not owner)")
    end
  end
  
private
  
  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Profile.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to profiles_url(current_user.id) }
      format.xml { render :xml => err.to_xml }
    end
  end
end
