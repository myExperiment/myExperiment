class PoliciesController < ApplicationController
  before_filter :authorize
  
  before_filter :find_policies_auth, :only => [:index]
  before_filter :find_policy_auth, :only => [:show, :edit, :update, :destroy]
  
  # GET /policies
  # GET /policies.xml
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @policies.to_xml }
    end
  end

  # GET /policies/1
  # GET /policies/1.xml
  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @policy.to_xml }
    end
  end

  # GET /policies/new
  def new
    @policy = Policy.new
  end

  # GET /policies/1;edit
  def edit

  end

  # POST /policies
  # POST /policies.xml
  def create
    @policy = Policy.new(params[:policy])
    
    respond_to do |format|
      if @policy.save
        flash[:notice] = 'Policy was successfully created.'
        format.html { redirect_to policy_url(@policy) }
        format.xml  { head :created, :location => policy_url(@policy) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @policy.errors.to_xml }
      end
    end
  end

  # PUT /policies/1
  # PUT /policies/1.xml
  def update
    respond_to do |format|
      if @policy.update_attributes(params[:policy])
        flash[:notice] = 'Policy was successfully updated.'
        format.html { redirect_to policy_url(@policy) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @policy.errors.to_xml }
      end
    end
  end

  # DELETE /policies/1
  # DELETE /policies/1.xml
  def destroy
    @policy.destroy

    respond_to do |format|
      format.html { redirect_to policies_url }
      format.xml  { head :ok }
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
    flash[:notice] = notice
    (err = Policy.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to policies_url }
      format.xml { render :xml => err.to_xml }
    end
  end
end
