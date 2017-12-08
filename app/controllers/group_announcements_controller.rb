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
        render :action => 'feed.rxml', :layout => false
      end
    end
  end

  # GET /group_announcements/1
  def show
    respond_to do |format|
      format.html {

        @lod_nir  = network_group_announcement_url(:id => @announcement.id, :network_id => @announcement.network_id)
        @lod_html = network_group_announcement_url(:id => @announcement.id, :network_id => @announcement.network_id, :format => 'html')
        @lod_rdf  = network_group_announcement_url(:id => @announcement.id, :network_id => @announcement.network_id, :format => 'rdf')
        @lod_xml  = network_group_announcement_url(:id => @announcement.id, :network_id => @announcement.network_id, :format => 'xml')

        # show.rhtml
      }

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

        Activity.create_activities(:subject => @announcement.user, :action => 'create', :object => @announcement)

        flash[:notice] = 'Group announcement was successfully created.'
        format.html { redirect_to network_group_announcements_path(@group) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /group_announcements/1
  def update
    respond_to do |format|
      if @announcement.update_attributes(params[:announcement])

        Activity.create_activities(:subject => @announcement.user, :action => 'edit', :object => @announcement)

        flash[:notice] = 'GroupAnnouncement was successfully updated'
        format.html { redirect_to network_group_announcement_path(@group, @announcement) }
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
      format.html { redirect_to network_group_announcements_path(@group) }
    end
  end
  
  
  protected
  
  def find_group
    @group = Network.find_by_id(params[:network_id])

    if @group.nil?
      render_404("Group not found.")
    end
  end

  
  def check_admin
    unless @group.administrator?(current_user)
      render_401("Only group administrators are allowed to create new announcements.")
    end
  end

  
  def find_announcements_auth
    # check if the user is member of a group ->
    # if not, show only public announcements
    @announcements = @group.announcements_for_user(current_user)
  end
  
  
  def find_announcement_auth
    # find the announcement first
    @announcement = GroupAnnouncement.find_by_id_and_network_id(params[:id], params[:network_id])

    if @announcement.nil?
      render_404("Group announcement not found.")
    else

      # at this point, group announcement is found and it definitely belongs to the group in URL;
      # now go through different actions and check which links are allowed for current user
      case action_name.to_s.downcase
        when "show"
          # if the announcement is private, show it only to group members
          unless @announcement.public || (logged_in? && @group.member?(current_user))
            render_401("You are not authorized to view this group announcement.")
          end
        when "edit","update","destroy"
          # only owner of the group can destroy the announcement
          unless logged_in? && ((@announcement.user == current_user) || (@group.owner?(current_user)))
            render_401("You are not authorized to #{action_name.to_s.downcase} this group announcement.")
          end
      end
    end
  end
end
