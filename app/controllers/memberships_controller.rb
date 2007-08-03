class MembershipsController < ApplicationController
  before_filter :authorize, :except => [:index, :show]
  
  before_filter :find_memberships, :only => [:index]
  before_filter :find_membership, :only => [:show]
  before_filter :find_membership_auth, :only => [:accept, :edit, :update, :destroy]
  
  # GET /networks/1/memberships/1;accept
  # GET /networks/1/memberships/1.xml;accept
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
  # GET /networks/1/memberships
  # GET /networks/1/memberships.xml
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
  # GET /networks/1/memberships/1
  # GET /networks/1/memberships/1.xml
  # GET /memberships/1
  # GET /memberships/1.xml
  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @membership.to_xml }
    end
  end

  # GET /users/1/memberships/new
  # GET /networks/1/memberships/new
  # GET /memberships/new
  def new
    if params[:network_id]
      begin
        n = Network.find(params[:network_id])
        
        @membership = Membership.new(:user_id => current_user.id, :network_id => n.id)
      rescue ActiveRecord::RecordNotFound
        error("Network not found", "is invalid", :network_id)
      end
    else
      @membership = Membership.new(:user_id => current_user.id)
    end
  end

  # GET /networks/1/memberships/1;edit
  # GET /memberships/1;edit
  def edit
    
  end

  # POST /users/1/memberships
  # POST /users/1/memberships.xml
  # POST /networks/1/memberships
  # POST /networks/1/memberships.xml
  # POST /memberships
  # POST /memberships.xml
  def create
    if (@membership = Membership.new(params[:membership]) unless Membership.find_by_user_id_and_network_id(params[:membership][:user_id], params[:membership][:network_id]))
      # set initial datetime
      @membership.created_at = Time.now
      @membership.accepted_at = nil

      respond_to do |format|
        if @membership.save
          flash[:notice] = 'Membership was successfully created.'
          format.html { redirect_to membership_url(@membership.network_id, @membership) }
          format.xml  { head :created, :location => membership_url(@membership.network_id, @membership) }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @membership.errors.to_xml }
        end
      end
    else
      error("Membership not created (already exists)", "not created, already exists")
    end
  end

  # PUT /networks/1/memberships/1
  # PUT /networks/1/memberships/1.xml
  # PUT /memberships/1
  # PUT /memberships/1.xml
  def update
    respond_to do |format|
      if @membership.update_attributes(params[:membership])
        flash[:notice] = 'Membership was successfully updated.'
        format.html { redirect_to membership_url(@membership.network_id, @membership) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @membership.errors.to_xml }
      end
    end
  end

  # DELETE /networks/1/memberships/1
  # DELETE /networks/1/memberships/1.xml
  # DELETE /memberships/1
  # DELETE /memberships/1.xml
  def destroy
    @membership.destroy

    respond_to do |format|
      format.html { redirect_to memberships_url }
      format.xml  { head :ok }
    end
  end
  
protected

  def find_memberships
    if params[:user_id]
      begin
        u = User.find(params[:user_id])
    
        @memberships = u.memberships
      rescue ActiveRecord::RecordNotFound
        error("User not found", "is invalid", :user_id)
      end
    elsif params[:network_id]
      begin
        n = Network.find(params[:network_id])
    
        @memberships = n.memberships
      rescue ActiveRecord::RecordNotFound
        error("Network not found", "is invalid", :network_id)
      end
    else
      @memberships = Membership.find(:all, :order => "created_at DESC")
    end
  end

  def find_membership
    if params[:user_id]
      begin
        u = User.find(params[:user_id])
    
        begin
          @membership = Membership.find(params[:id], :conditions => ["user_id = ?", u.id])
        rescue ActiveRecord::RecordNotFound
          error("Membership not found", "is invalid")
        end
      rescue ActiveRecord::RecordNotFound
        error("User not found", "is invalid", :user_id)
      end
    elsif params[:network_id]
      begin
        n = Network.find(params[:network_id])
    
        begin
          @membership = Membership.find(params[:id], :conditions => ["network_id = ?", n.id])
        rescue ActiveRecord::RecordNotFound
          error("Membership not found", "is invalid")
        end
      rescue ActiveRecord::RecordNotFound
        error("Network not found", "is invalid", :network_id)
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
    if params[:network_id]
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
      error("Friendship not found (id not authorized)", "is invalid (not owner)")
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
