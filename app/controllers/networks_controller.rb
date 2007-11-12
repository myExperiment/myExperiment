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

class NetworksController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :search, :all]
  
  before_filter :find_networks, :only => [:index, :all]
  before_filter :find_network, :only => [:membership_request, :show]
  before_filter :find_network_auth, :only => [:membership_create, :edit, :update, :destroy]
  
  # GET /networks;search
  # GET /networks.xml;search
  def search
    @query = @query = params[:query] == nil ? "" : params[:query] + "~"
    
    @networks = Network.find_with_ferret(@query, :limit => :all)
    
    respond_to do |format|
      format.html # search.rhtml
      format.xml  { render :xml => @networks.to_xml }
    end
  end
  
  # GET /networks/1;membership_create
  def membership_create
    respond_to do |format|
      unless params[:user_id]
        flash[:error] = 'Failed to add User to Group. Please report this error.'
        format.html { redirect_to network_url(@network) }
      end
      
      @membership = Membership.new(:user_id => params[:user_id], :network_id => @network.id)
        
      if @membership.save
        @membership.accept!
        flash[:notice] = 'User successfully added to Group.'
        format.html { redirect_to network_url(@network) }
      else
        flash[:error] = 'Failed to add User to Group. Please try again or report this.'
        format.html { redirect_to network_url(@network) }
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
  
  # GET /networks/all
  def all
    respond_to do |format|
      format.html # all.rhtml
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
    @network = Network.new(:user_id => current_user.id)
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
      @networks = Network.find(:all, 
                               :conditions => ["user_id = ?", params[:user_id]], 
                               :order => "title ASC",
                               :page => { :size => 20, 
                                          :current => params[:page] })
    else  
      @networks = Network.find(:all, 
                               :order => "title ASC",
                               :page => { :size => 20, 
                                          :current => params[:page] })
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
