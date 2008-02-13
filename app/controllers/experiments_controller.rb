# myExperiment: app/controllers/experiments_controller.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class ExperimentsController < ApplicationController
  
  before_filter :login_required
  
  before_filter :find_experiments, :only => [:index]
  before_filter :find_experiment, :except => [:search, :index, :new, :create, :all]
  
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  def show
    @experiment = Experiment.find(params[:id])
  end

  def new
    @experiment = Experiment.new
  end

  def create
    @experiment = Experiment.new(params[:experiment])
    if @experiment.save
      flash[:notice] = 'Experiment was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @experiment = Experiment.find(params[:id])
  end

  def update
    @experiment = Experiment.find(params[:id])
    if @experiment.update_attributes(params[:experiment])
      flash[:notice] = 'Experiment was successfully updated.'
      redirect_to :action => 'show', :id => @experiment
    else
      render :action => 'edit'
    end
  end

  def destroy
    Experiment.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
