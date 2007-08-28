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

class MembershipsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  
  before_filter :find_memberships, :only => [:index]
  before_filter :find_membership, :only => [:show]
  before_filter :find_membership_auth, :only => [:accept, :edit, :update, :destroy]
  
  # GET /users/1/memberships/1;accept
  # GET /users/1/memberships/1.xml;accept
  # GET /memberships/1;accept
  # GET /memberships/1.xml;accept
  def accept
    respond_to do |format|
      if @membership.accept!
        flash[:notice] = 'Membership was successfully accepted.'
        format.html { redirect_to memberships_url(current_user.id) }
        format.xml  { head :ok }
      else
        error("Membership already accepted", "already accepted")
      end
    end
  end
  
  # GET /users/1/memberships
  # GET /users/1/memberships.xml
  # GET /memberships
  # GET /memberships.xml
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @memberships.to_xml }
    end
  end

  # GET /users/1/memberships/1
  # GET /users/1/memberships/1.xml
  # GET /memberships/1
  # GET /memberships/1.xml
  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @membership.to_xml }
    end
  end

  # GET /users/1/memberships/new
  # GET /memberships/new
  def new
    if params[:network_id]
      begin
        @network = Network.find(params[:network_id])
        
        @membership = Membership.new(:user_id => current_user.id, :network_id => @network.id)
      rescue ActiveRecord::RecordNotFound
        error("Network not found", "is invalid", :network_id)
      end
    else
      @membership = Membership.new(:user_id => current_user.id)
    end
  end

  # GET /users/1/memberships/1;edit
  # GET /memberships/1;edit
  def edit
    
  end

  # POST /users/1/memberships
  # POST /users/1/memberships.xml
  # POST /memberships
  # POST /memberships.xml
  def create
    if (@membership = Membership.new(params[:membership]) unless Membership.find_by_user_id_and_network_id(params[:membership][:user_id], params[:membership][:network_id]) or Network.find(params[:membership][:network_id]).owner? params[:membership][:user_id])
      # set initial datetime
      @membership.accepted_at = nil

      respond_to do |format|
        if @membership.save
          flash[:notice] = 'Membership was successfully requested.'
          format.html { redirect_to membership_url(@membership.user_id, @membership) }
          format.xml  { head :created, :location => membership_url(@membership.user_id, @membership) }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @membership.errors.to_xml }
        end
      end
    else
      error("Membership not created (already exists)", "not created, already exists")
    end
  end

  # PUT /users/1/memberships/1
  # PUT /users/1/memberships/1.xml
  # PUT /memberships/1
  # PUT /memberships/1.xml
  def update
    # no spoofing of acceptance
    params[:membership].delete('accepted_at') if params[:membership][:accepted_at]
    
    respond_to do |format|
      if @membership.update_attributes(params[:membership])
        flash[:notice] = 'Membership was successfully updated.'
        format.html { redirect_to membership_url(@membership.user_id, @membership) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @membership.errors.to_xml }
      end
    end
  end

  # DELETE /users/1/memberships/1
  # DELETE /users/1/memberships/1.xml
  # DELETE /memberships/1
  # DELETE /memberships/1.xml
  def destroy
    network_id = @membership.network_id
    
    @membership.destroy

    respond_to do |format|
      format.html { redirect_to network_path(network_id) }
      format.xml  { head :ok }
    end
  end
  
protected

  def find_memberships
    if params[:user_id]
      begin
        @user = User.find(params[:user_id])
    
        @memberships = @user.memberships
      rescue ActiveRecord::RecordNotFound
        error("User not found", "is invalid", :user_id)
      end
    else
      @memberships = Membership.find(:all, :order => "created_at DESC")
    end
  end

  def find_membership
    if params[:user_id]
      begin
        @user = User.find(params[:user_id])
    
        begin
          @membership = Membership.find(params[:id], :conditions => ["user_id = ?", @user.id])
        rescue ActiveRecord::RecordNotFound
          error("Membership not found", "is invalid")
        end
      rescue ActiveRecord::RecordNotFound
        error("User not found", "is invalid", :user_id)
      end
    else
      begin
        @membership = Membership.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        error("Membership not found", "is invalid")
      end
    end
  end
  
  def find_membership_auth
    if params[:user_id]
      begin
        membership = Membership.find(params[:id])
        
        if Network.find(membership.network_id).owner? current_user.id
          @membership = membership
        else
          error("Membership not found (id not authorized)", "is invalid (not owner)", :network_id)
        end
      rescue ActiveRecord::RecordNotFound
        error("Membership not found", "is invalid")
      end
    else
      error("Membership not found (id not authorized)", "is invalid (not owner)")
    end
  end
  
private
  
  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Membership.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to memberships_url(current_user.id) }
      format.xml { render :xml => err.to_xml }
    end
  end
end
