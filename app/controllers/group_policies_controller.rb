# myExperiment: app/controllers/group_policies_controller.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

class GroupPoliciesController < ApplicationController

  include ApplicationHelper
  
  before_filter :login_required
  before_filter :find_group
  before_filter :find_policy, :only => [:show, :edit, :update, :destroy]
  before_filter :check_admin

  def index
    @policies = Policy.find_all_by_contributor_type_and_contributor_id('Network', @group.id)

    respond_to do |format|
      format.html
    end
  end

  def show
    respond_to do |format|
      format.html { render :action => "edit" }
    end
  end

  def new
    @policy = Policy.new
  end

  def edit
    
  end

  def create
    @policy = Policy.new(:name => params[:name],
                         :contributor => @group,
                         :share_mode  => params[:share_mode],
                         :update_mode => 6
    )

    respond_to do |format|
      if @policy.save
        process_permissions(@policy, params)
        update_layout(@policy, params[:layout])
        flash[:notice] = 'Policy was successfully created.'
        format.html { redirect_to network_policies_path(@group) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    respond_to do |format|
      if @policy.update_attributes(:name => params[:name], :share_mode => params[:share_mode])
        process_permissions(@policy, params)
        update_layout(@policy, params[:layout])
        flash[:notice] = 'Policy was successfully updated'
        format.html { redirect_to network_policies_path(@group) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    if @policy.contributions.size == 0
      @policy.destroy

      respond_to do |format|
        flash[:notice] = "Policy was successfully deleted"
        format.html { redirect_to network_policies_path(@group) }
      end
    else
      error("This policy is being used by #{@policy.contributions.size} resources and may not be deleted.")
    end
  end
  
  
  protected
  
  def find_group
    begin
      @group = Network.find(params[:network_id])
    rescue ActiveRecord::RecordNotFound
      error("Group couldn't be found")
    end
  end

  def find_policy
    begin
      @policy = Policy.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error("Policy couldn't be found")
    end
  end

  
  def check_admin
    unless @group.administrator?(current_user.id)
      error("Only group administrators are allowed to manage policies")
    end
  end

  private

  def error(message)
    flash[:error] = message
    return_to_path = @group.nil? ? networks_path : network_policies_path(@group)
    
    respond_to do |format|
      format.html { redirect_to return_to_path }
    end
  end

  
end
