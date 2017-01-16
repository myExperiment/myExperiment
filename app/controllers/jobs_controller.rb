# myExperiment: app/controllers/jobs_controller.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class JobsController < ApplicationController
  
  before_filter :login_required
  
  before_filter :check_runner_available, :only => [:new, :update]
  
  before_filter :find_experiment
  before_filter :auth_experiment, :except => [:create, :new]
  
  before_filter :find_jobs, :only => [:index]
  before_filter :find_job_auth, :except => [:index, :new, :create]
  
  before_filter :check_runnable_supported, :only => [:new, :create]
  
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  def show
    unless Authorization.check("view", @job.runnable, current_user)
      flash[:error] = "<p>You will not be able to submit this Job, but you can still see the details of it."
      flash[:error] = "<p>The runnable item (#{@job.runnable_type}) is not authorized - you need download priviledges to run it.</p>"
    end
    
    # TODO: check that runnable version still exists
    
    unless Authorization.check("view", @job, current_user)
      flash[:error] = "You will not be able to submit this Job, but you can still see the details of it." unless flash[:error]
      flash[:error] += "<p>The runner is not authorized - you need to either own it or be part of a Group that owns it.</p>"
    end
    
    @job.refresh_status!

    respond_to do |format|
      format.html {
        
        @lod_nir  = experiment_job_url(:id => @job.id, :experiment_id => @experiment.id)
        @lod_html = experiment_job_url(:id => @job.id, :experiment_id => @experiment.id, :format => 'html')
        @lod_rdf  = experiment_job_url(:id => @job.id, :experiment_id => @experiment.id, :format => 'rdf')
        @lod_xml  = experiment_job_url(:id => @job.id, :experiment_id => @experiment.id, :format => 'xml')
        
        # show.rhtml
      }

      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} jobs #{@job.id}`
        }
      end
    end
  end

  def new
    @job = Job.new
    @job.experiment = @experiment if @experiment
    
    # Set defaults
    @job.title = Job.default_title(current_user)
    @job.runnable_type = "Workflow"
    @job.runner_type = "TavernaEnactor"
    
    @job.runnable_id = params[:runnable_id] if params[:runnable_id]
    @job.runnable_version = params[:runnable_version] if params[:runnable_version]
    
    # Check that the runnable object is allowed.
    # At the moment: only Taverna 1 workflows are allowed.
    if params[:runnable_id] 
      runnable = Workflow.find(:first, :conditions => ["id = ?", params[:runnable_id]])
      if runnable 
        if runnable.processor_class != WorkflowProcessors::TavernaScufl
          flash[:error] = "Note that the workflow specified to run in this job is currently not supported and will prevent the job from being created. Specify a Taverna 1 workflow instead."
        end
        
        # TODO: check that the specified version of the workflow exists so that a warning can be given.
      else
        flash[:error] = "Note that the workflow specified to run in this job does not exist. Specify a different workflow."
      end
    end
    
    respond_to do |format|
      format.html # new.rhtml
    end
  end

  def self.create_job(params, user)
    success = true
    err_msg = nil
    
    # Hard code certain values, for now.
    params[:job][:runnable_type] = 'Workflow'
    params[:job][:runner_type] = 'TavernaEnactor'
    
    @job = Job.new(params[:job])
    @job.user = user
    
    # Check runnable is a valid and authorized one
    # (for now we can assume it's a Workflow)
    runnable = Workflow.find(:first, :conditions => ["id = ?", params[:job][:runnable_id]])
    
    # Check that the runnable object is allowed to be run.
    # At the moment: only Taverna 1 workflows are allowed.
    if runnable 
      if runnable.processor_class != WorkflowProcessors::TavernaScufl
        success = false
        err_msg = "The workflow specified to run in this job not supported. Please specify a Taverna 1 workflow instead."
      end
    end
    
    if not runnable or not Authorization.check('download', runnable, user)
      success = false
      @job.errors.add(:runnable_id, "not valid or not authorized")
    else
      # Look for the specific version of that Workflow
      unless runnable.find_version(params[:job][:runnable_version])
        success = false
        @job.errors.add(:runnable_version, "not valid")
      end
    end
    
    # Check runner is a valid and authorized one
    # (for now we can assume it's a TavernaEnactor)
    runner = TavernaEnactor.find(:first, :conditions => ["id = ?", params[:job][:runner_id]])
    if not runner or not Authorization.check('execute', runner, user)
      success = false
      @job.errors.add(:runner_id, "not valid or not authorized")
    end
    
    success = update_parent_experiment(params, @job, user)
    
    return @job, success, err_msg
  end

  def create

    @job, success, err_msg = JobsController.create_job(params, current_user)

    respond_to do |format|
      if success and @job.save
        flash[:notice] = "Job successfully created."
        format.html { redirect_to experiment_job_path(@job.experiment, @job) }
      else
        flash[:error] = err_msg if err_msg
        format.html { render :action => "new" }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html # edit.rhtml
    end
  end

  def update
    respond_to do |format|
      if @job.update_attributes(params[:job])
        flash[:notice] = "Job was successfully updated."
        format.html { redirect_to experiment_job_path(@experiment, @job) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @job.destroy
        flash[:notice] = "Job \"#{@job.title}\" has been deleted"
        format.html { redirect_to experiment_jobs_path(@experiment) }
      else
        flash[:error] = "Failed to delete Job"
        format.html { redirect_to experiment_job_path(@experiment, @job) }
      end
    end
  end
  
  def save_inputs
    inputs_hash = { }
    
    input_ports = @job.runnable.get_input_ports(@job.runnable_version)
    
    input_ports.each do |i|
      case params["#{i.name}_input_type".to_sym]
      when "none"
        inputs_hash[i.name] = nil
      when "single"
        inputs_hash[i.name] = params["#{i.name}_single_input".to_sym]
      when "list"
        h = params["#{i.name}_list_input".to_sym]
        if h and h.is_a?(Hash)
          # Need to sort because we need to assume that order is important!
          h = h.sort {|a,b| a[0]<=>b[0]}
          vals = [ ]
          h.each do |v|
            vals << v[1]
          end
          inputs_hash[i.name] = vals
        else
          flash[:error] += "Failed to read list of inputs for port: #{i.name}. "
        end
      when "file"
        inputs_hash[i.name] = params["#{i.name}_file_input".to_sym].read
      end
    end
    
    @job.inputs_data = inputs_hash
    
    respond_to do |format|
      if @job.save  
        flash[:notice] = "Input data successfully saved" if flash[:error].blank?
      else
        flash[:error] = "An error has occurred whilst saving the inputs data"
      end
      
      format.html { redirect_to experiment_job_path(@experiment, @job) }
    end
  end
  
  def submit_job
    success = true
    errors_text = ''
    
    # Authorize the runnable and runner
    unless Authorization.check("download", @job.runnable, current_user)
      success = false;
      errors_text += "<p>The runnable item (#{@job.runnable_type}) is not authorized - you need download priviledges to run it.</p>"
    end
    
    unless Authorization.check("edit", @job, current_user)
      success = false;
      errors_text += "<p>The runner is not authorized - you need to either own it or be part of a Group that owns it.</p>"
    end
    
    if success
      success = @job.submit_and_run!
    end
    
    unless success
      @job.run_errors.each do |err|
        errors_text += "<p>#{err}</p>"  
      end
    end
    
    respond_to do |format|
      if success
        flash[:notice] = "Job has been successfully submitted. You can monitor progress in the 'Status' section."
        format.html { redirect_to experiment_job_path(@experiment, @job) }
      else
        flash[:error] = "Failed to submit job. Errors: " + errors_text
        format.html { redirect_to experiment_job_path(@experiment, @job) }
      end
    end
  end
  
  def refresh_status
    @job.refresh_status!
    @stop_timer = (@job.allow_run? or @job.completed?)
    logger.debug("Stop timer? - #{@stop_timer}")
    respond_to do |format|
      format.html { render :partial => "status_info", :locals => { :job => @job, :experiment => @experiment } }
    end
  end
  
  def refresh_outputs
    respond_to do |format|
      format.html { render :partial => "outputs", :locals => { :job => @job, :experiment => @experiment } }
    end
  end
  
  def outputs_xml
      if @job.completed?
        send_data(@job.outputs_as_xml, :filename => "Job_#{@job.id}_#{@job.title}_outputs.xml", :type => "application/xml")
      else
        respond_to do |format|
          flash[:error] = "Outputs XML unavailable - Job not completed successfully yet."
          format.html { redirect_to experiment_job_path(@experiment, @job) }
        end
      end
  end
  
  def outputs_package
    
  end
  
  def rerun
    child_job = Job.new
    
    child_job.title = Job.default_title(current_user)
    child_job.experiment = @job.experiment
    child_job.user = current_user
    child_job.runnable = @job.runnable
    child_job.runnable_version = @job.runnable_version
    child_job.runner = @job.runner
    child_job.inputs_data = @job.inputs_data
    child_job.parent_job = @job
    
    respond_to do |format|
      if child_job.save
        flash[:notice] = "Job successfully created, based on Job #{@job.title}'."
        format.html { redirect_to experiment_job_path(@experiment, child_job) }
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  def render_output
    # TODO: employ some form of caching here so that we don't have to always go back to the service for the outputs data.
    respond_to do |format|
      format.html { render :partial => "output_content", :locals => { :job => @job, :output_port => params[:output_port] } }
    end
  end
  
protected

  def self.update_parent_experiment(params, job, user)
    if params[:change_experiment]
      if params[:change_experiment] == 'new'
        job.experiment = Experiment.new(:title => Experiment.default_title(user), :contributor => user)
      elsif params[:change_experiment] == 'existing'
        experiment = Experiment.find(params[:change_experiment_id])
        if experiment and Authorization.check('edit', experiment, user)
          job.experiment = experiment
        else
          flash[:error] = "Job could not be created because could not assign the parent Experiment."
          return false
        end
      end
    else
      job.experiment = @experiment
    end
    
    return true
  end
  
  def check_runner_available
    if TavernaEnactor.for_user(current_user).empty?
      flash[:error] = "You cannot create a job until you have access to an enactment service registered as a runner here."
      respond_to do |format|
        format.html { redirect_to new_runner_path }
      end
    end
  end

  def find_experiment
    return if ["create","new"].include?(action_name) && params[:experiment_id].nil?

    @experiment = Experiment.find_by_id(params[:experiment_id])
    
    if @experiment.nil?
      render_404("Experiment not found.")
    end
  end

  def auth_experiment
    return if ["create","new"].include?(action_name) && params[:experiment_id].nil?

    action_permissions = {
      "create"  => "create",
      "destroy" => "destroy",
      "edit"    => "edit",
      "index"   => "view",
      "new"     => "create",
      "show"    => "view",
      "update"  => "edit"
    }

    unless Authorization.check(action_permissions[action_name], @experiment, current_user)
      render_401("You are not authorized to access this experiment.")
    end
  end
  
  def find_jobs
    @jobs = Job.find(:all, :conditions => ["experiment_id = ?", params[:experiment_id]])
  end

  def find_job_auth

    action_permissions = {
      "create"          => "create",
      "destroy"         => "destroy",
      "edit"            => "edit",
      "index"           => "view",
      "new"             => "create",
      "outputs_package" => "download",
      "outputs_xml"     => "download",
      "refresh_outputs" => "download",
      "refresh_status"  => "download",
      "render_output"   => "download",
      "rerun"           => "download",
      "save_inputs"     => "download",
      "show"            => "view",
      "submit_job"      => "download",
      "update"          => "edit",
    }

    @job = Job.find_by_id(params[:id])
      
    if @job.nil? || @job.experiment.id != @experiment.id
      render_404("Job not found.")
    elsif !Authorization.check(action_permissions[action_name], @job, current_user)
      render_401("Action not authorized.")
    end
  end
  
  def check_runnable_supported
    # TODO: move all checks for the runnable object here!
  end
end
