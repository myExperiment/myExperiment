class NetworksController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  
  before_filter :find_networks, :only => [:index]
  before_filter :find_network, :only => [:membership_create, :membership_request, :show]
  before_filter :find_network_auth, :only => [:edit, :update, :destroy]
  
  # GET /networks/1;membership_create
  def membership_create
    respond_to do |format|
      if @network.owner? current_user.id
        membership = Membership.new(:user_id => params[:user_id], :network_id => @network.id)
        
        if membership.save
          if membership.accept!
            format.html { render :partial => "networks/member", :locals => { :network => @network, :member => membership.user } }
            format.xml  { head :ok }
          else
            error("Membership already accepted", "already accepted")
          end
        else
          error("Membership already created", "already created")
        end
      else
        error("Not Network owner", "not network owner")
      end
    end
  end
  
  # GET /networks/1;membership_request
  def membership_request
    redirect_to :controller => 'memberships', 
                :action => 'new', 
                :user_id => current_user.id,
                :network_id => @network.id
  end
  
  # GET /networks
  # GET /networks.xml
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @networks.to_xml }
    end
  end

  # GET /networks/1
  # GET /networks/1.xml
  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @network.to_xml }
    end
  end

  # GET /networks/new
  def new
    @network = Network.new
  end

  # GET /networks/1;edit
  def edit
    
  end

  # POST /networks
  # POST /networks.xml
  def create
    @network = Network.new(params[:network])

    respond_to do |format|
      if @network.save
        flash[:notice] = 'Network was successfully created.'
        format.html { redirect_to network_url(@network) }
        format.xml  { head :created, :location => network_url(@network) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @network.errors.to_xml }
      end
    end
  end

  # PUT /networks/1
  # PUT /networks/1.xml
  def update
    respond_to do |format|
      if @network.update_attributes(params[:network])
        flash[:notice] = 'Network was successfully updated.'
        format.html { redirect_to network_url(@network) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @network.errors.to_xml }
      end
    end
  end

  # DELETE /networks/1
  # DELETE /networks/1.xml
  def destroy
    @network.destroy

    respond_to do |format|
      format.html { redirect_to networks_url }
      format.xml  { head :ok }
    end
  end
  
protected

  def find_networks
    if params[:user_id]
      @networks = Network.find(:all, :conditions => ["user_id = ?", params[:user_id]], :order => "created_at DESC")
    else  
      @networks = Network.find(:all, :order => "created_at DESC")
    end
  end

  def find_network
    begin
      @network = Network.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error("Network not found", "is invalid (not owner)")
    end
  end

  def find_network_auth
    begin
      @network = Network.find(params[:id], :conditions => ["user_id = ?", current_user.id])
    rescue ActiveRecord::RecordNotFound
      error("Network not found (id not authorized)", "is invalid (not owner)")
    end
  end
  
private

  def error(notice, message)
    flash[:notice] = notice
    (err = Network.new.errors).add(:id, message)
    
    respond_to do |format|
      format.html { redirect_to networks_url }
      format.xml { render :xml => err.to_xml }
    end
  end
end
