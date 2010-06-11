# myExperiment: app/controllers/group_announcements_controller.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

class GroupAnnouncementsController < ApplicationController
  
  before_filter :login_required, :except => [ :index, :show ]
  
  before_filter :find_group
  before_filter :check_admin, :only => [ :new, :create ] # admin check for editing is done in "find_announcement_auth"
  before_filter :find_announcements_auth, :only => [ :index ]
  before_filter :find_announcement_auth, :only => [ :show, :edit, :update, :destroy ]
  
  # declare sweepers and which actions should invoke them
  cache_sweeper :group_announcement_sweeper, :only => [ :create, :update, :destroy ]
  
  # GET /group_announcements
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.rss do
        render :action => 'index.rxml', :layout => false
      end
    end
  end

  # GET /group_announcements/1
  def show
    respond_to do |format|
      format.html # show.rhtml

      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} group_announcements #{@announcement.id}`
        }
      end
    end
  end

  # GET /group_announcements/new
  def new
    @announcement = GroupAnnouncement.new()
  end

  # GET /group_announcements/1;edit
  def edit
    
  end

  # TODO
  # POST /group_announcements
  def create
    @announcement = GroupAnnouncement.new(params[:announcement])
    @announcement.network = @group
    @announcement.user_id = current_user.id

    respond_to do |format|
      if @announcement.save
        flash[:notice] = 'Group announcement was successfully created.'
        format.html { redirect_to group_announcements_url(@group) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /group_announcements/1
  def update
    respond_to do |format|
      if @announcement.update_attributes(params[:announcement])
        flash[:notice] = 'GroupAnnouncement was successfully updated'
        format.html { redirect_to group_announcement_url(@group, @announcement) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /group_announcements/1
  def destroy
    @announcement.destroy

    respond_to do |format|
      flash[:notice] = "Group announcement was successfully deleted"
      format.html { redirect_to group_announcements_url(@group) }
    end
  end
  
  
  protected
  
  def find_group
    begin
      @group = Network.find(params[:group_id])
    rescue ActiveRecord::RecordNotFound
      error("Group couldn't be found")
      return false
    end
  end

  
  def check_admin
    unless @group.owner?(current_user.id)
      error("Only group administrators are allowed to create new announcements")
      return false
    end
  end

  
  def find_announcements_auth
    # check if the user is member of a group ->
    # if not, show only public announcements
    @announcements = @group.announcements_for_user(current_user)
  end
  
  
  def find_announcement_auth
    begin
      begin
        # find the announcement first
        @announcement = GroupAnnouncement.find(params[:id])
      
        # announcement found, but check if belongs to the group in URL
        unless @group.announcements.include?(@announcement)
          raise ActiveRecord::RecordNotFound
        end
      rescue ActiveRecord::RecordNotFound
        raise ActiveRecord::RecordNotFound, "Group announcement was not found"
      end
      
      # at this point, group announcement is found and it definitely belongs to the group in URL;
      # now go through different actions and check which links are allowed for current user
      not_auth = false
      case action_name.to_s.downcase
        when "show"
          # if the announcement is private, show it only to group members
          unless @announcement.public 
            not_auth = true unless @group.member?(current_user.id)
          end
        when "edit","update","destroy"
          # only owner of the group can destroy the announcement
          unless @group.owner?(current_user.id)
            not_auth = true;
            raise ActiveRecord::RecordNotFound, "You don't have permissions to perform this action"
          end
        else
          # don't allow anything else, for now
          not_auth = true
      end
      
      
      # check if we had any errors
      if not_auth
        raise ActiveRecord::RecordNotFound, "Group announcement was not found"
      end
      
    rescue ActiveRecord::RecordNotFound => exc
      error(exc.message)
    end
  end
  
  
  private

  def error(message)
    flash[:error] = message
    return_to_path = @group.nil? ? groups_path : group_announcements_path(@group)
    
    respond_to do |format|
      format.html { redirect_to return_to_path }
    end
  end

  
end
