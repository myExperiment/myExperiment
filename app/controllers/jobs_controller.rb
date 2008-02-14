# myExperiment: app/controllers/jobs_controller.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class JobsController < ApplicationController
  
  before_filter :login_required
  
  before_filter :find_experiment_auth
  
  before_filter :find_jobs, :only => [:index]
  before_filter :find_job_auth, :only => [:show, :edit, :update, :destroy]
  
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  def show
    respond_to do |format|
      format.html # show.rhtml
    end
  end

  def new
    @job = Job.new
    @job.experiment = @experiment
    respond_to do |format|
      format.html # new.rhtml
    end
  end

  def create
    @job = Job.new(params[:job])
    @job.experiment = @experiment
    # TODO: add other custom logic for creation
    respond_to do |format|
      if @job.save
        flash[:notice] = "Job successfully created."
        format.html { redirect_to job_url(@experiment, @job) }
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
  
protected

  def find_experiment_auth
    experiment = Experiment.find(params[:experiment_id])
    
    if experiment and experiment.authorized?(action_name, current_user)
      @experiment = experiment
    else
      error("The Experiment that this Job belongs to could not be found or the action is not authorized", "is invalid (not authorized)")
    end
  end

  def find_job_auth
    job = Job.find(params[:id])
      
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
