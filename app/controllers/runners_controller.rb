# myExperiment: app/controllers/runners_controller.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class RunnersController < ApplicationController
  
  # NOTE (Feb 2008): this controller will be used for the handling of any runner type.
  
  before_filter :login_required
  
  before_filter :find_runners, :only => [:index]
  before_filter :find_runner_auth, :only => [:show, :edit, :update, :destroy, :verify]
  
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  def show
    respond_to do |format|
      format.html {

        @lod_nir  = runner_url(@runner)
        @lod_html = formatted_runner_url(:id => @runner.id, :format => 'html')
        @lod_rdf  = formatted_runner_url(:id => @runner.id, :format => 'rdf')
        @lod_xml  = formatted_runner_url(:id => @runner.id, :format => 'xml')

        # show.rhtml
      }

      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} runners #{@runner.id}`
        }
      end
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
    respond_to do |format|
      if update_runner!(@runner)
        flash[:notice] = "Your Runner of type 'Taverna Enactor' has been successfully registered."
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

  def update
    respond_to do |format|
      if update_runner!(@runner)
        flash[:notice] = "Your Runner of type 'Taverna Enactor' has been successfully updated."
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
  
  def verify
    respond_to do |format|
      format.html { render :partial => "status", :locals => { :service_valid => @runner.service_valid? } }
    end
  end
  
protected

  def update_runner!(runner)
    success = true
    
    runner.title = params[:runner][:title] if params[:runner][:title]
    runner.description = params[:runner][:description] if params[:runner][:description]
    runner.url = params[:runner][:url] if params[:runner][:url]
    runner.username = params[:runner][:username] if params[:runner][:username]
    runner.password = params[:runner][:password] if params[:runner][:password]
    
    if params[:assign_to_group]
      network = Network.find(params[:assign_to_group_id])
      if network and network.member?(current_user.id)
        @runner.contributor = network
      else
        flash[:error] = "Experiment could not be created because could not assign ownership to Group."
        success = false
      end
    else
      @runner.contributor = current_user
    end
    
    success ? @runner.save : false
  end

  def find_runners
    @personal_runners = TavernaEnactor.find_by_contributor('User', current_user.id)
    @group_runners = TavernaEnactor.find_by_groups(current_user)
  end
  
  def find_runner_auth
    runner = TavernaEnactor.find(:first, :conditions => ["id = ?", params[:id]])
    
    if runner and Authorization.is_authorized?(action_name, nil, runner, current_user)
      @runner = runner
    else
      error("Runner not found or action not authorized", "is invalid (not authorized)")
    end
  end
  
private

  def error(notice, message, attr=:id)
    flash[:error] = notice
    (err = TavernaEnactor.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to runners_url }
    end
  end
end
