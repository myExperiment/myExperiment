# myExperiment: app/controllers/citations_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class CitationsController < ApplicationController
  before_filter :login_required, :except => [ :index, :show ]
  
  before_filter :find_workflow_auth
  
  before_filter :find_citations, :only => :index
  before_filter :find_citation, :only => :show
  before_filter :find_citation_auth, :only => [ :edit, :update, :destroy ]
  
  # declare sweepers and which actions should invoke them
  cache_sweeper :citation_sweeper, :only => [ :create, :update, :destroy ]
  
  # GET /citations
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # GET /citations/1
  def show
    respond_to do |format|
      format.html # show.rhtml
    end
  end

  # GET /citations/new
  def new
    @citation = Citation.new(:user => current_user, :workflow => @workflow, :workflow_version => @workflow.versions.length, :accessed_at => nil)
  end

  # GET /citations/1;edit
  def edit
    
  end

  # POST /citations
  def create
    params[:user_id], params[:workflow_id], params[:workflow_version] = current_user.id, @workflow.id, @workflow.versions.length
    
    @citation = Citation.new(params[:citation])

    respond_to do |format|
      if @citation.save

        Activity.create(:subject => current_user, :action => 'create', :objekt => @citation, :auth => @workflow)
        flash[:notice] = 'Citation was successfully created.'
        format.html { redirect_to workflow_citation_url(@workflow, @citation) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /citations/1
  def update
    respond_to do |format|
      if @citation.update_attributes(params[:citation])
        Activity.create(:subject => current_user, :action => 'edit', :objekt => @citation, :auth => @workflow)
        flash[:notice] = 'Citation was successfully updated.'
        format.html { redirect_to workflow_citation_url(@workflow, @citation) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /citations/1
  def destroy
    @citation.destroy

    respond_to do |format|
      flash[:notice] = 'Citation was successfully deleted.'
      format.html { redirect_to workflow_citations_url(@workflow) }
    end
  end
  
protected

  def find_workflow_auth
    begin
      # attempt to authenticate the user before you return the workflow
      login_required if login_available?
    
      workflow = Workflow.find(params[:workflow_id])
      
      if Authorization.check((["index", "show"].include?(action_name) ? "view" : "edit"), workflow, current_user)
        @workflow = workflow
        
        # remove workflow data from workflow if the user is not authorized for download
        @workflow.content_blob.data = nil unless Authorization.check("download", @workflow, current_user)
      else
        if logged_in?
          error("Workflow not found (id not authorized)", "is invalid (not authorized)")
        else
          find_workflow_auth if login_required
        end
      end
    rescue ActiveRecord::RecordNotFound
      error("Workflow not found", "is invalid")
    end
  end
  
  def find_citations
    if @workflow
      @citations = @workflow.citations
    else
      @citations = []
    end
  end
  
  def find_citation
    if citation = @workflow.citations.find(:first, :conditions => ["id = ?", params[:id]])
      @citation = citation
    else
      error("Citation not found", "is invalid", params[:id])
    end
  end
  
  def find_citation_auth
    if citation = @workflow.citations.find(:first, :conditions => ["id = ? AND user_id = ?", params[:id], current_user.id])
      @citation = citation
    else
      error("Citation not found (id not authorized)", "is invalid (not authorized)", params[:id])
    end
  end
  
private

  def error(notice, message, attr=nil)
    flash[:error] = notice

    workflow_id_attr = attr
    workflow_id_attr = :id if workflow_id_attr.nil?

    (err = Citation.new.errors).add(workflow_id_attr, message)

    respond_to do |format|
      format.html {
        if attr
          redirect_to workflow_citations_url(params[:workflow_id])
        else
          redirect_to workflows_url
        end
      }
    end
  end
  
end
