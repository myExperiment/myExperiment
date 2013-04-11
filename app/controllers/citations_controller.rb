# myExperiment: app/controllers/citations_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class CitationsController < ApplicationController
  before_filter :login_required, :except => [ :index, :show ]
  
  before_filter :find_workflow
  before_filter :auth_view_workflow, :only => [:index, :show]
  before_filter :auth_edit_workflow, :only => :create
  before_filter :find_citation, :only => [:show, :edit, :update, :destroy ]
  before_filter :auth_citation, :only => [:edit, :update, :destroy ]
  
  # declare sweepers and which actions should invoke them
  cache_sweeper :citation_sweeper, :only => [ :create, :update, :destroy ]
  
  # GET /citations
  def index
    @citations = @workflow.citations

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

  def find_workflow
    if (@workflow = Workflow.find_by_id(params[:workflow_id])).nil?
      render_404("Workflow not found.")
    end
  end

  def auth_view_workflow
    unless Authorization.check("view", @workflow, current_user)
      render_401("You are not authorized to view this workflow's citations.")
    end
  end

  def auth_edit_workflow
    unless Authorization.check("edit", @workflow, current_user)
      render_401("You are not authorized to manage this workflow's citations.")
    end
  end

  def find_citation
    if (@citation = @workflow.citations.find(:first, :conditions => ["id = ?", params[:id]])).nil?
      render_404("Citation not found.")
    end
  end
  
  def auth_citation
    unless @citation.user == current_user
      render_401("You are not authorized to #{action_name} this citation.")
    end
  end
end
