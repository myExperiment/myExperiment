# myExperiment: app/controllers/relationships_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class RelationshipsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  
  before_filter :find_relationships, :only => [:index]
  before_filter :find_relationship, :only => [:show]
  before_filter :find_relationship_auth, :only => [:accept, :edit, :update, :destroy]
  
  # GET /networks/1/relationships/1;accept
  # GET /relationships/1;accept
  def accept
    respond_to do |format|
      if @relationship.accept!
        flash[:notice] = 'Relationship was successfully accepted.'
        format.html { redirect_to relationships_url(@relationship.network_id) }
      else
        error("Relationship already accepted", "already accepted")
      end
    end
  end
  
  # GET /networks/1/relationships
  # GET /relationships
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # GET /networks/1/relationships/1
  # GET /relationships/1
  def show
    respond_to do |format|
      format.html # show.rhtml
    end
  end

  # GET /networks/1/relationships/new
  # GET /relationships/new
  def new
    if params[:network_id]
      @relationship = Relationship.new(:network_id => params[:network_id])
    else
      @relationship = Relationship.new
    end
    
    # only allow relation_id to be in @owned_networks
    @networks_owned = current_user.networks_owned
  end

  # GET /networks/1/relationships/1;edit
  # GET /relationships/1;edit
  def edit
    
  end

  # POST /networks/1/relationships
  # POST /relationships
  def create
    if (@relationship = Relationship.new(params[:relationship]) unless Relationship.find_by_network_id_and_relation_id(params[:relationship][:network_id], params[:relationship][:relation_id]))
      # set initial datetime
      @relationship.accepted_at = nil
      
      # current_user must be the owner of Network.find(relation_id)
      @relationship.errors.add :relation_id, "not authorized (not owned)" unless current_user.networks_owned.include? Network.find(params[:relationship][:network_id])

      respond_to do |format|
        if @relationship.save
          flash[:notice] = 'Relationship was successfully created.'
          format.html { redirect_to relationship_url(@relationship.network_id, @relationship) }
        else
          format.html { render :action => "new" }
        end
      end
    else
      error("Relationship not created (already exists)", "not created, already exists")
    end
  end

  # PUT /networks/1/relationships/1
  # PUT /relationships/1
  def update
    # no spoofing of acceptance
    params[:relationship].delete('accepted_at') if params[:relationship][:accepted_at]
    
    respond_to do |format|
      if @relationship.update_attributes(params[:relationship])
        flash[:notice] = 'Relationship was successfully updated.'
        format.html { redirect_to relationship_url(@relationship.network_id, @relationship) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /networks/1/relationships/1
  # DELETE /relationships/1
  def destroy
    network_id = @relationship.network_id
    
    @relationship.destroy

    respond_to do |format|
      format.html { redirect_to relationships_url(network_id) }
    end
  end
  
protected

  def find_relationships
    if params[:network_id]
      begin
        n = Network.find(params[:network_id])
      
        @relationships = n.relationships
      rescue ActiveRecord::RecordNotFound
        error("Network not found", "is invalid", :network_id)
      end
    else
      @relationships = Relationship.find(:all, :order => "created_at DESC")
    end
  end

  def find_relationship
    if params[:network_id]
      begin
        n = Network.find(params[:network_id])
    
        begin
          @relationship = Relationship.find(params[:id], :conditions => ["network_id = ?", n.id])
        rescue ActiveRecord::RecordNotFound
          error("Relationship not found", "is invalid")
        end
      rescue ActiveRecord::RecordNotFound
        error("Network not found", "is invalid", :network_id)
      end
    else
      begin
        @relationship = Relationship.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        error("Relationship not found", "is invalid")
      end
    end
  end
  
  def find_relationship_auth
    if params[:network_id]
      begin
        relationship = Relationship.find(params[:id])
      
        if Network.find(relationship.network_id).owner? current_user.id
          @relationship = relationship
        else
          error("Relationship not found (id not authorized)", "is invalid (not owner)", :network_id)
        end
      rescue ActiveRecord::RecordNotFound
        error("Relationship not found", "is invalid")
      end
    else
      error("Relationship not found (id not authorized)", "is invalid (not owner)")
    end
  end

private

  def error(notice, message, attr=:id)
    flash[:error] = notice
    (err = Relationship.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to relationships_url(params[:network_id]) }
    end
  end
end
