# myExperiment: app/controllers/jobs_controller.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class JobsController < ApplicationController
  
  before_filter :login_required
  
  before_filter :find_experiment_auth
  
  before_filter :find_jobs, :only => [:index]
  before_filter :find_job_auth, :except => [:index, :new, :create]
  
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  def show
    unless @job.runnable.authorized?(action_name, current_user)
      flash[:error] = "<p>You will not be able to submit this Job, but you can still see the details of it."
      flash[:error] = "<p>The runnable item (#{@job.runnable_type}) is not authorized - you need download priviledges to run it.</p>"
    end
    
    # TODO: check that runnable version still exists
    
    unless @job.runner.authorized?(action_name, current_user)
      flash[:error] = "You will not be able to submit this Job, but you can still see the details of it." unless flash[:error]
      flash[:error] += "<p>The runner is not authorized - you need to either own it or be part of a Group that owns it.</p>"
    end
    
    @job.refresh_status!

    respond_to do |format|
      format.html # show.rhtml
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
    
    respond_to do |format|
      format.html # new.rhtml
    end
  end

  def create
    success = true
    
    # Hard code certain values, for now.
    params[:job][:runnable_type] = 'Workflow'
    params[:job][:runner_type] = 'TavernaEnactor'
    
    @job = Job.new(params[:job])
    @job.user = current_user
    
    # Check runnable is a valid and authorized one
    # (for now we can assume it's a Workflow)
    runnable = Workflow.find(:first, :conditions => ["id = ?", params[:job][:runnable_id]])
    if !runnable or !runnable.authorized?('download', current_user)
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
    if !runner or !runner.authorized?('execute', current_user)
      success = false
      @job.errors.add(:runner_id, "not valid or not authorized")
    end
    
    success = update_parent_experiment(@job)
    
    respond_to do |format|
      if success and @job.save
        flash[:notice] = "Job successfully created."
        format.html { redirect_to job_url(@job.experiment, @job) }
      else
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
        format.html { redirect_to job_url(@experiment, @job) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @job.destroy
        flash[:notice] = "Job \"#{@job.title}\" has been deleted"
        format.html { redirect_to jobs_url(@experiment) }
      else
        flash[:error] = "Failed to delete Job"
        format.html { redirect_to job_url(@experiment, @job) }
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
      
      format.html { redirect_to job_url(@experiment, @job) }
    end
  end
  
  def submit_job
    success = true
    errors_text = ''
    
    # Authorize the runnable and runner
    
    unless @job.runnable.authorized?(action_name, current_user) 
      success = false;
      errors_text += "<p>The runnable item (#{@job.runnable_type}) is not authorized - you need download priviledges to run it.</p>"
    end
    
    unless @job.runner.authorized?(action_name, current_user) 
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
        format.html { redirect_to job_url(@experiment, @job) }
      else
        flash[:error] = "Failed to submit job. Errors: " + errors_text
        format.html { redirect_to job_url(@experiment, @job) }
      end
    end
  end
  
  def refresh_status
    @job.refresh_status!
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
          format.html { redirect_to job_url(@experiment, @job) }
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
        format.html { redirect_to job_url(@experiment, child_job) }
      else
        format.html { render :action => "new" }
      end
    end
  end
  
protected

  def update_parent_experiment(job)
    if params[:change_experiment]
      if params[:change_experiment] == 'new'
        job.experiment = Experiment.new(:title => Experiment.default_title(current_user), :contributor => current_user)
      elsif params[:change_experiment] == 'existing'
        experiment = Experiment.find(params[:change_experiment_id])
        if experiment and experiment.authorized?('edit', current_user)
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

  def find_experiment_auth
    experiment = Experiment.find(:first, :conditions => ["id = ?", params[:experiment_id]])
    
    if experiment and experiment.authorized?(action_name, current_user)
      @experiment = experiment
    else
      # New and Create actions are allowed to run outside of the context of an Experiment
      unless ['new', 'create'].include?(action_name.downcase)
        error("The Experiment that this Job belongs to could not be found or the action is not authorized", "is invalid (not authorized)")
      end
    end
  end
  
  def find_jobs
    @jobs = Job.find(:all, :conditions => ["experiment_id = ?", params[:experiment_id]])
  end

  def find_job_auth
    job = Job.find(:first, :conditions => ["id = ?", params[:id]])
      
    if job and job.authorized?(action_name, current_user)
      @job = job
    else
      error("Job not found or action not authorized", "is invalid (not authorized)")
    end
  end
  
private

  def error(notice, message, attr=:id)
    flash[:error] = notice
    (err = Job.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to jobs_url(params[:experiment_id]) }
      format.xml { render :xml => err.to_xml }
    end
  end
end
