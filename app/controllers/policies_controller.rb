# myExperiment: app/controllers/policies_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class PoliciesController < ApplicationController
  before_filter :login_required
  
  before_filter :find_policies_auth, :only => [:index]
  before_filter :find_policy_auth, :only => [:test, :show, :edit, :update, :destroy]
  
  # POST /policies/1;test
  def test
    contribution, contributor = Contribution.find(params[:contribution_id]), nil
    
    # hack for javascript contributor selection form
    case params[:contributor_type].to_s
    when "User"
      contributor = User.find(params[:user_contributor_id])
    when "Network"
      contributor = Network.find(params[:network_contributor_id])
    else
      error("Contributor ID not selected", "not selected", :contributor_id)  
    end
    
    respond_to do |format|
      format.html { render :partial => "policies/test_results", :locals => { :policy => @policy, :contribution => contribution, :contributor => contributor } }
    end
  end
  
  # GET /policies
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # GET /policies/1
  def show
    respond_to do |format|
      format.html # show.rhtml
    end
  end

  # GET /policies/new
  def new
    @policy = Policy.new
    
    @policy.contributor_id = current_user.id
    @policy.contributor_type = current_user.class.to_s
  end

  # GET /policies/1;edit
  def edit

  end

  # POST /policies
  def create
    @policy = Policy.new(params[:policy])
    
    respond_to do |format|
      if @policy.save
        flash[:notice] = 'Policy was successfully created.'
        format.html { redirect_to policy_url(@policy) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /policies/1
  def update
    respond_to do |format|
      if @policy.update_attributes(params[:policy])
        flash[:notice] = 'Policy was successfully updated.'
        format.html { redirect_to policy_url(@policy) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /policies/1
  def destroy
    @policy.destroy

    respond_to do |format|
      format.html { redirect_to policies_url }
    end
  end
  
protected

  def find_policies_auth
    @policies = Policy.find(:all, :conditions => ["contributor_id = ? AND contributor_type = ?", current_user.id, current_user.class.to_s])
  end
  
  def find_policy_auth
    begin
      @policy = Policy.find(params[:id], :conditions => ["contributor_id = ? AND contributor_type = ?", current_user.id, current_user.class.to_s])
    rescue ActiveRecord::RecordNotFound
      error("Policy not found (id not authorized)", "is invalid (not owner)")
    end
  end

private

  def error(notice, message, attr=:id)
    flash[:error] = notice
    (err = Policy.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to policies_url }
    end
  end
end
