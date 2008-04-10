# myExperiment: app/controllers/contributions_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class ContributionsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  
  before_filter :find_contributions, :only => [:index]
  before_filter :find_contribution, :only => [:show]
  before_filter :find_contribution_auth, :only => [:edit, :update, :destroy]
  
  # GET /contributions
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # GET /contributions/1
  def show
    respond_to do |format|
      format.html # show.rhtml
    end
  end

  # GET /contributions/new
  def new
    @contribution = Contribution.new
  end

  # GET /contributions/1;edit
  def edit

  end

  # POST /contributions
  def create
    @contribution = Contribution.new(params[:contribution])

    respond_to do |format|
      if @contribution.save
        flash[:notice] = 'Contribution was successfully created.'
        format.html { redirect_to contribution_url(@contribution) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /contributions/1
  def update
    # hack for select contributor form
    if params[:contributor_pair]
      params[:contribution][:contributor_type], params[:contribution][:contributor_id] = params[:contributor_pair][:class_id].split("-")
      params.delete("contributor_pair")
    end
    
    # security bugfix: do not allow owner to change protected columns
    [:contributable_id, :contributable_type].each do |column_name|
      params[:contribution].delete(column_name)
    end
    
    # bug fix to not save 'default' workflow unless policy_id is selected
    @contribution.policy = nil if (params[:policy_id].nil? or params[:policy_id].empty?)
    
    respond_to do |format|
      if @contribution.update_attributes(params[:contribution])
        flash[:notice] = 'Contribution was successfully updated.'
        format.html { redirect_to contribution_url(@contribution) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /contributions/1
  def destroy
    @contribution.destroy

    respond_to do |format|
      format.html { redirect_to contributions_url }
    end
  end
  
protected

  def find_contributions()
    valid_keys = ["contributor_id", "contributor_type", "contributable_type"]
    
    cond_sql = ""
    cond_params = []
    
    params.each do |key, value|
      if valid_keys.include? key
        cond_sql << " AND " unless cond_sql.empty?
        cond_sql << "#{key} = ?" 
        cond_params << value
      end
    end
    
    options = { :order => "contributable_type ASC, created_at DESC",
                :page => { :size => 20, 
                           :current => params[:page] } }
    options = options.merge( { :conditions => [cond_sql] + cond_params }) unless cond_sql.empty?
    
    @contributions = Contribution.find(:all, options)
  end
  
  def find_contribution
    begin
      contribution = Contribution.find(params[:id])
      
      if contribution.authorized?(action_name, (logged_in? ? current_user : nil))
        @contribution = contribution
      else
        error("Contribution not found (id not authorized)", "is invalid (not authorized)")
      end
    rescue ActiveRecord::RecordNotFound
      error("Contribution not found", "is invalid")
    end
  end
  
  def find_contribution_auth
    begin
      contribution = Contribution.find(params[:id])
      
      if contribution.owner?(current_user)
        @contribution = contribution
      else
        error("Contribution not found (id not owner)", "is invalid (not owner)")
      end
    rescue ActiveRecord::RecordNotFound
      error("Contribution not found", "is invalid")
    end
  end

private

  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Contribution.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to contributions_url }
    end
  end
end
