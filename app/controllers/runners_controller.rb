# myExperiment: app/controllers/runners_controller.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class RunnersController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @taverna_enactor_pages, @taverna_enactors = paginate :taverna_enactors, :per_page => 10
  end

  def show
    @taverna_enactor = TavernaEnactor.find(params[:id])
  end

  def new
    @taverna_enactor = TavernaEnactor.new
  end

  def create
    @taverna_enactor = TavernaEnactor.new(params[:taverna_enactor])
    if @taverna_enactor.save
      flash[:notice] = 'TavernaEnactor was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @taverna_enactor = TavernaEnactor.find(params[:id])
  end

  def update
    @taverna_enactor = TavernaEnactor.find(params[:id])
    if @taverna_enactor.update_attributes(params[:taverna_enactor])
      flash[:notice] = 'TavernaEnactor was successfully updated.'
      redirect_to :action => 'show', :id => @taverna_enactor
    else
      render :action => 'edit'
    end
  end

  def destroy
    TavernaEnactor.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
