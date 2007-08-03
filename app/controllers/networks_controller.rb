class NetworksController < ApplicationController
  before_filter :authorize, :except => [:index, :show]
  
  before_filter :find_networks, :only => [:index]
  before_filter :find_network, :only => [:show]
  before_filter :find_network_auth, :only => [:edit, :update, :destroy]
  
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
    
    # set initial datetime
    @network.created_at = @network.updated_at = Time.now

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
    # update datetime
    @network.updated_at = Time.now

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
    @networks = Network.find(:all, :order => "created_at DESC")
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
