# myExperiment: app/controllers/announcements_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class AnnouncementsController < ApplicationController
  before_filter :check_admin, :except => [:show, :index]
  
  before_filter :find_announcements, :only => [:index]
  
  # declare sweepers and which actions should invoke them
  cache_sweeper :announcement_sweeper, :only => [ :create, :update, :destroy ]
  
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.rss do
        render :action => 'index.rxml', :layout => false
      end
    end
  end

  def show
    @announcement = Announcement.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml

      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} announcements #{@announcement.id}`
        }
      end
    end
  end

  def new
    @announcement = Announcement.new
  end

  def create
    params[:announcement][:user_id] = current_user.id
    @announcement = Announcement.new(params[:announcement])
    if @announcement.save
      flash[:notice] = 'Announcement was successfully created.'
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  def edit
    @announcement = Announcement.find(params[:id])
  end

  def update
    @announcement = Announcement.find(params[:id])
    if @announcement.update_attributes(params[:announcement])
      flash[:notice] = 'Announcement was successfully updated.'
      redirect_to :action => 'show', :id => @announcement
    else
      render :action => 'edit'
    end
  end

  def destroy
    Announcement.find(params[:id]).destroy
    redirect_to :action => 'index'
  end
  
protected

  def check_admin
    unless admin?
      flash[:error] = 'Only administrators have access to create, update and delete announcements.'
      redirect_to :action => 'index'
    end
  end
  
  def find_announcements
    @announcements = Announcement.find(:all, :order => "created_at DESC")
  end
  
end
