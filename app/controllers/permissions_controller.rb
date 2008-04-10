# myExperiment: app/controllers/permissions_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class PermissionsController < ApplicationController
  before_filter :login_required
  
  before_filter :find_permissions_auth, :only => [:index]
  before_filter :find_permission_auth, :only => [:show, :edit, :update, :destroy]
  
  # GET /policies/1/permissions
  # GET /permissions
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # GET /policies/1/permissions
  # GET /permissions/1
  def show
    respond_to do |format|
      format.html # show.rhtml
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
  # POST /permissions
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
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /policies/1/permissions/1
  # PUT /permissions/1
  def update
    respond_to do |format|
      if @permission.update_attributes(params[:permission])
        flash[:notice] = 'Permission was successfully updated.'
        #format.html { redirect_to permission_url(@permission.policy, @permission) }
        format.html { redirect_to policy_url(@permission.policy) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /policies/1/permissions/1
  # DELETE /permissions/1
  def destroy
    policy = @permission.policy
    
    @permission.destroy

    respond_to do |format|
      #format.html { redirect_to permissions_url(@permission.policy)}
      format.html { redirect_to policy_url(policy) }
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
          @policy = policy
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
    end
  end
end
