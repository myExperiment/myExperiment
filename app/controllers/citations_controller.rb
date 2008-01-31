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
  
  # GET /citations
  # GET /citations.xml
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @citations.to_xml }
    end
  end

  # GET /citations/1
  # GET /citations/1.xml
  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @citation.to_xml }
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
  # POST /citations.xml
  def create
    params[:user_id], params[:workflow_id], params[:workflow_version] = current_user.id, @workflow.id, @workflow.versions.length
    
    @citation = Citation.new(params[:citation])

    respond_to do |format|
      if @citation.save
        flash[:notice] = 'Citation was successfully created.'
        format.html { redirect_to citation_url(@workflow, @citation) }
        format.xml  { head :created, :location => citation_url(@workflow, @citation) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @citation.errors.to_xml }
      end
    end
  end

  # PUT /citations/1
  # PUT /citations/1.xml
  def update
    respond_to do |format|
      if @citation.update_attributes(params[:citation])
        flash[:notice] = 'Citation was successfully updated.'
        format.html { redirect_to citation_url(@workflow, @citation) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @citation.errors.to_xml }
      end
    end
  end

  # DELETE /citations/1
  # DELETE /citations/1.xml
  def destroy
    @citation.destroy

    respond_to do |format|
      flash[:notice] = 'Citation was successfully deleted.'
      format.html { redirect_to citations_url(@workflow) }
      format.xml  { head :ok }
    end
  end
  
protected

  def find_workflow_auth
    begin
      # attempt to authenticate the user before you return the workflow
      login_required if login_available?
    
      workflow = Workflow.find(params[:workflow_id])
      
      if workflow.authorized?((["index", "show"].include?(action_name) ? "show" : "edit"), (logged_in? ? current_user : nil))
        @workflow = workflow
        
        # remove scufl from workflow if the user is not authorized for download
        @workflow.scufl = nil unless @workflow.authorized?("download", (logged_in? ? current_user : nil))
      else
        if logged_in?
          error("Workflow not found (id not authorized)", "is invalid (not authorized)", :workflow_id)
        else
          find_workflow_auth if login_required
        end
      end
    rescue ActiveRecord::RecordNotFound
      error("Workflow not found", "is invalid", :workflow_id)
    end
  end
  
  def find_citations
    @citations = @workflow.citations
  end
  
  def find_citation
    if citation = @workflow.citations.find(:first, :conditions => ["id = ?", params[:id]])
      @citation = citation
    else
      error("Citation not found", "is invalid")
    end
  end
  
  def find_citation_auth
    if citation = @workflow.citations.find(:first, :conditions => ["id = ? AND user_id = ?", params[:id], current_user.id])
      @citation = citation
    else
      error("Citation not found (id not authorized)", "is invalid (not authorized)")
    end
  end

private

  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Citation.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to citations_url(params[:workflow_id]) }
      format.xml { render :xml => err.to_xml }
    end
  end
  
end
