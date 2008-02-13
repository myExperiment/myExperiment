# myExperiment: app/controllers/jobs_controller.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class JobsController < ApplicationController
  
  before_filter :login_required, :except => [ :index, :show ]
  
  before_filter :find_reviewable_auth
  
  before_filter :find_reviews, :only => [ :index ]
  before_filter :find_review, :only => [ :show ]
  before_filter :find_review_auth, :only => [ :edit, :update, :destroy ]
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @job_pages, @jobs = paginate :jobs, :per_page => 10
  end

  def show
    @job = Job.find(params[:id])
  end

  def new
    @job = Job.new
  end

  def create
    @job = Job.new(params[:job])
    if @job.save
      flash[:notice] = 'Job was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @job = Job.find(params[:id])
  end

  def update
    @job = Job.find(params[:id])
    if @job.update_attributes(params[:job])
      flash[:notice] = 'Job was successfully updated.'
      redirect_to :action => 'show', :id => @job
    else
      render :action => 'edit'
    end
  end

  def destroy
    Job.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
