class WorkflowsController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :download]
  
  before_filter :find_workflows, :only => [:index]
  before_filter :find_workflow_auth, :only => [:download, :show, :edit, :update, :destroy]
  
  require 'scufl/model'
  require 'scufl/parser'
  require 'scufl/dot'
  
  # if RUBY_PLATFORM =~ /mswin32/
  #   require 'win32/open3'
  # end
  
  # GET /workflows/1;download
  # GET /workflows/1.xml;download
  def download
    send_data(@workflow.scufl, :filename => @workflow.unique + ".xml", :type => "text/xml")
  end
  
  # GET /workflows
  # GET /workflows.xml
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @workflows.to_xml }
    end
  end

  # GET /workflows/1
  # GET /workflows/1.xml
  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @workflow.to_xml }
    end
  end

  # GET /workflows/new
  def new
    @workflow = Workflow.new
  end

  # GET /workflows/1;edit
  def edit
    
  end

  # POST /workflows
  # POST /workflows.xml
  def create
    # hack for select contributor form
    if params[:contributor_pair]
      params[:workflow][:contributor_type], params[:workflow][:contributor_id] = params[:contributor_pair][:class_id].split("-")
      params.delete("contributor_pair")
    end
    
    # create workflow using helper methods
    @workflow = create_workflow(params[:workflow])
    
    respond_to do |format|
      if @workflow.save
        # if the user selects a different contributor_pair
        # --> @contributable.contributor = params[:contributor_pair]
        #     @contributable.contribution.contributor = current_user
        @workflow.update_attribute(:contributor_id, current_user.id) if @workflow.contribution.contributor_id.to_i != current_user.id.to_i
        @workflow.update_attribute(:contributor_type, current_user.class.to_s) if @workflow.contribution.contributor_type.to_s != current_user.class.to_s
        
        @workflow.contribution.update_attributes(params[:contribution])
        
        flash[:notice] = 'Workflow was successfully created.'
        format.html { redirect_to workflow_url(@workflow) }
        format.xml  { head :created, :location => workflow_url(@workflow) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @workflow.errors.to_xml }
      end
    end
  end

  # PUT /workflows/1
  # PUT /workflows/1.xml
  def update
    # update contributor with 'latest' uploader (or "editor")
    @workflow.contributor_id = current_user.id
    @workflow.contributor_type = current_user.class.to_s
    
    respond_to do |format|
      if @workflow.update_attributes(params[:workflow])
        # security fix (only allow the owner to change the policy)
        @workflow.contribution.update_attributes(params[:contribution]) if @workflow.contribution.owner?(current_user)
        
        flash[:notice] = 'Workflow was successfully updated.'
        format.html { redirect_to workflow_url(@workflow) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @workflow.errors.to_xml }
      end
    end
  end

  # DELETE /workflows/1
  # DELETE /workflows/1.xml
  def destroy
    @workflow.destroy

    respond_to do |format|
      format.html { redirect_to workflows_url }
      format.xml  { head :ok }
    end
  end
  
protected

  def find_workflows
    @workflows = Workflow.find(:all, :order => "updated_at DESC")
  end
  
  def find_workflow_auth
    begin
      workflow = Workflow.find(params[:id])
      
      if workflow.authorized?(action_name, (logged_in? ? current_user : nil))
        if params[:version]
          if workflow.revert_to(params[:version])
            @workflow = workflow
          else
            error("Version not found (is invalid)", "not found (is invalid)", :version)
          end
        else
          @workflow = workflow
        end
      else
        error("Workflow not found (id not authorized)", "is invalid (not authorized)")
      end
    rescue ActiveRecord::RecordNotFound
      error("Workflow not found", "is invalid")
    end
  end
  
  def create_workflow(wf)
    scufl_model = Scufl::Parser.new.parse(wf[:scufl].read)
    wf[:scufl].rewind
    
    salt = rand 32768
    title, unique = scufl_model.description.title.blank? ? ["untitled", "untitled_#{salt}"] : [scufl_model.description.title,  "#{scufl_model.description.title.gsub(/[^\w\.\-]/,'_').downcase}_#{salt}"]
    
    i = Tempfile.new("image")
    Scufl::Dot.new.write_dot(i, scufl_model)
    i.close(false)
    d = StringIO.new(`dot -Tpng #{i.path}`)
    i.unlink
    d.extend FileUpload
    d.original_filename = "#{unique}.png"
    d.content_type = "image/png"
    
    return Workflow.new(:scufl => wf[:scufl].read, 
                        :image => d,
                        :contributor_id => wf[:contributor_id], 
                        :contributor_type => wf[:contributor_type],
                        :title => title,
                        :unique => unique,
                        :description => scufl_model.description.description)
  end

private

  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Workflow.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to workflows_url }
      format.xml { render :xml => err.to_xml }
    end
  end
end

module FileUpload
  attr_accessor :original_filename, :content_type
end
