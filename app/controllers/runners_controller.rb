# myExperiment: app/controllers/runners_controller.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class RunnersController < ApplicationController
  
  # NOTE (Feb 2008): this controller will be used for the handling of any runner type.
  
  before_filter :login_required
  
  before_filter :find_runners, :only => [:index]
  before_filter :find_runner_auth, :only => [:show, :edit, :update, :destroy]
  
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
    @runner = TavernaEnactor.new
    respond_to do |format|
      format.html # new.rhtml
    end
  end

  def create
    @runner = TavernaEnactor.new
    @runner.title = params[:runner][:title]
    @runner.description = params[:runner][:description]
    @runner.url = params[:runner][:url]
    @runner.username = params[:runner][:username]
    @runner.password = params[:runner][:password]
    @runner.contributor = current_user
    
    respond_to do |format|
      if @runner.save
        flash[:notice] = "Your Runner of type 'Taverna Enactor' has successfully been registered."
        format.html { redirect_to runner_url(@runner) }
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

  # TODO: need to make this action more generic, like the "create" action.
  def update
    respond_to do |format|
      if @runner.update_attributes(params[:taverna_enactor])
        flash[:notice] = "Your Taverna Enactor Runner has been successfully updated."
        format.html { redirect_to runner_url(@runner) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @runner.destroy
        flash[:notice] = "Runner \"#{@runner.title}\" has been deleted"
        format.html { redirect_to runners_url }
      else
        flash[:error] = "Failed to delete Runner"
        format.html { redirect_to runner_url(@runner) }
      end
    end
  end
  
protected

  def find_runners
    # Currently, only return the runners for the current user
    @runners = TavernaEnactor.find(:all, :conditions => ["contributor_type = ? AND contributor_type = ?", 'User', current_user.id])
  end
  
  def find_runner_auth
    runner = TavernaEnactor.find(:first, :conditions => ["id = ?", params[:id]])
    
    if runner and runner.authorized?(action_name, current_user)
      @runner = runner
    else
      error("Runner not found or action not authorized", "is invalid (not authorized)")
    end
  end
  
private

  def error(notice, message, attr=:id)
    flash[:error] = notice
    (err = Runner.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to runners_url }
    end
  end
end
