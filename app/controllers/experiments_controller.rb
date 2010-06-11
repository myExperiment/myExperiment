# myExperiment: app/controllers/experiments_controller.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class ExperimentsController < ApplicationController
  
  before_filter :login_required
  
  before_filter :find_experiments, :only => [:index]
  before_filter :find_experiment_auth, :only => [:show, :edit, :update, :destroy]
  
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  def show
    respond_to do |format|
      format.html # show.rhtml

      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} experiments #{@experiment.id}`
        }
      end
    end
  end

  def new
    @experiment = Experiment.new
    # Set a default title
    @experiment.title = Experiment.default_title(current_user)
    respond_to do |format|
      format.html # new.rhtml
    end
  end

  def create
    @experiment = Experiment.new(params[:experiment])
    respond_to do |format|
      if update_ownership(@experiment) and @experiment.save
        flash[:notice] = "Your new Experiment has successfully been created."
        format.html { redirect_to experiment_url(@experiment) }
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
      if update_ownership(@experiment) and @experiment.update_attributes(params[:experiment])
        flash[:notice] = "Experiment was successfully updated."
        format.html { redirect_to experiment_url(@experiment) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @experiment.destroy
        flash[:notice] = "Experiment \"#{@experiment.title}\" has been deleted"
        format.html { redirect_to experiments_url }
      else
        flash[:error] = "Failed to delete Experiment"
        format.html { redirect_to experiment_url(@experiment) }
      end
    end
  end
  
protected

  def update_ownership(experiment)
    success = true
    
    if params[:assign_to_group]
      network = Network.find(params[:assign_to_group_id])
      if network and network.member?(current_user.id)
        @experiment.contributor = network
      else
        flash[:error] = "Experiment could not be created because could not assign ownership to Group."
        success = false
      end
    else
      @experiment.contributor = current_user
    end
    
    return success
  end

  def find_experiments
    # Currently, only return the Experiments that the current user has access to,
    # ie: Experiments the user owns, and Experiments owned by the user's groups.
    @personal_experiments = Experiment.find_by_contributor('User', current_user.id)
    @group_experiments = Experiment.find_by_groups(current_user)
  end
  
  def find_experiment_auth
    experiment = Experiment.find(:first, :conditions => ["id = ?", params[:id]])
    
    if experiment and Authorization.is_authorized?(action_name, nil, experiment, current_user)
      @experiment = experiment
    else
      error("Experiment not found or action not authorized", "is invalid (not authorized)")
    end
  end
  
private

  def error(notice, message, attr=:id)
    flash[:error] = notice
    (err = Experiment.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to experiments_url }
    end
  end
end
