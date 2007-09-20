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

class PermissionsController < ApplicationController
  before_filter :login_required
  
  before_filter :find_permissions_auth, :only => [:index]
  before_filter :find_permission_auth, :only => [:show, :edit, :update, :destroy]
  
  # GET /policies/1/permissions
  # GET /policies/1/permissions.xml
  # GET /permissions
  # GET /permissions.xml
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @permissions.to_xml }
    end
  end

  # GET /policies/1/permissions
  # GET /policies/1/permissions.xml
  # GET /permissions/1
  # GET /permissions/1.xml
  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @permission.to_xml }
    end
  end

  # GET /policies/1/permissions/new
  # GET /permissions/new
  def new
    @permission = Permission.new
    
    begin
      policy = Policy.find(params[:policy_id], :conditions => ["contributor_id = ? AND contributor_type = ?", current_user.id, current_user.class.to_s])
      @permission.policy_id = policy.id
    rescue ActiveRecord::RecordNotFound
      error("Policy ID not supplied", "not supplied", :policy_id)
    end
  end

  # GET /policies/1/permissions/1;edit
  # GET /permissions/1;edit
  def edit
    
  end

  # POST /policies/1/permissions
  # POST /policies/1/permissions.xml
  # POST /permissions
  # POST /permissions.xml
  def create
    # hack for javascript contributor selection form
    case params[:permission][:contributor_type].to_s
    when "User"
      params[:permission][:contributor_id] = params[:user_contributor_id]
    when "Network"
      params[:permission][:contributor_id] = params[:network_contributor_id]
    else
      error("Contributor ID not selected", "not selected", :contributor_id)  
    end
    
    @permission = Permission.new(params[:permission])

    respond_to do |format|
      if @permission.save
        flash[:notice] = 'Permission was successfully created.'
        #format.html { redirect_to permission_url(@permission.policy, @permission) }
        format.html { redirect_to policy_url(@permission.policy) }
        format.xml  { head :created, :location => permission_url(@permission.policy, @permission) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @permission.errors.to_xml }
      end
    end
  end

  # PUT /policies/1/permissions/1
  # PUT /policies/1/permissions/1.xml
  # PUT /permissions/1
  # PUT /permissions/1.xml
  def update
    respond_to do |format|
      if @permission.update_attributes(params[:permission])
        flash[:notice] = 'Permission was successfully updated.'
        #format.html { redirect_to permission_url(@permission.policy, @permission) }
        format.html { redirect_to policy_url(@permission.policy) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @permission.errors.to_xml }
      end
    end
  end

  # DELETE /policies/1/permissions/1
  # DELETE /policies/1/permissions/1.xml
  # DELETE /permissions/1
  # DELETE /permissions/1.xml
  def destroy
    policy = @permission.policy
    
    @permission.destroy

    respond_to do |format|
      #format.html { redirect_to permissions_url(@permission.policy)}
      format.html { redirect_to policy_url(policy) }
      format.xml  { head :ok }
    end
  end
  
protected

  def find_permissions_auth
    if params[:policy_id]
      begin
        @policy = Policy.find(params[:policy_id], :conditions => ["contributor_id = ? AND contributor_type = ?", current_user.id, current_user.class.to_s])
        
        @permissions = @policy.permissions
      rescue ActiveRecord::RecordNotFound
        error("Policy not found (id not authorized)", "is invalid (not owner)", :policy_id)
      end
    else
      @permissions = []
      current_user.policies.each do |policy|
        policy.permissions.each do |permission|
          @permissions << permission
        end
      end
    end
  end

  def find_permission_auth
    begin
      permission = Permission.find(params[:id])
      
      params[:policy_id] ||= permission.policy.id
      
      begin
        policy = Policy.find(params[:policy_id], :conditions => ["contributor_id = ? AND contributor_type = ?", current_user.id, current_user.class.to_s])
        
        if permission.policy.id.to_i == policy.id.to_i
          @permission = permission
        else
          error("Permission not found (invalid Policy id)", "is invalid (does not match permission.policy_id)", :policy_id)
        end
      rescue ActiveRecord::RecordNotFound
        error("Policy not found (id not authorized)", "is invalid (not owner)", :policy_id)
      end
    rescue ActiveRecord::RecordNotFound
      error("Permission not found (does not exist)", "is invalid (not found)")
    end
  end
  
private

  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Permission.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to policies_url }
      format.xml { render :xml => err.to_xml }
    end
  end
end
