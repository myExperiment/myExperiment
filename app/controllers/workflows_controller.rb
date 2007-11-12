##
##
## myExperiment - a social network for scientists
##
## Copyright (C) 2007 University of Manchester/University of Southampton
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License
## as published by the Free Software Foundation; either version 3 of the
## License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program; if not, see http://www.gnu.org/licenses
## or write to the Free Software Foundation,Inc., 51 Franklin Street,
## Fifth Floor, Boston, MA 02110-1301  USA
##
##

class WorkflowsController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :download, :search, :all]
  
  before_filter :find_workflows, :only => [:index, :all]
  #before_filter :find_workflow_auth, :only => [:bookmark, :comment, :rate, :tag, :download, :show, :edit, :update, :destroy]
  before_filter :find_workflow_auth, :except => [:search, :index, :new, :create, :all]
  
  require 'scufl/model'
  require 'scufl/parser'
  require 'scufl/dot'
  
  # GET /workflows;search
  # GET /workflows.xml;search
  def search
    # why is there a + "~"
    # @query = params[:query] == nil ? "" : params[:query] + "~"
    @query = params[:query]
    
    @workflows = Workflow.find_with_ferret(@query, :sort => Ferret::Search::SortField.new(:rating, :reverse => true), :limit => :all)
    
    respond_to do |format|
      format.html # search.rhtml
      format.xml  { render :xml => @workflows.to_xml }
    end
  end
  
  # POST /workflows/1;bookmark
  # POST /workflows/1.xml;bookmark
  def bookmark
    @workflow.bookmarks << Bookmark.create(:user => current_user, :title => @workflow.title) unless @workflow.bookmarked_by_user?(current_user)
    
    respond_to do |format|
      format.html { render :inline => "<%=h @workflow.bookmarks.collect {|b| b.user.name}.join(', ') %>" }
      format.xml { render :xml => @workflow.bookmarks.to_xml }
    end
  end
  
  # POST /workflows/1;comment
  # POST /workflows/1.xml;comment
  def comment
    comment = Comment.create(:user => current_user, :comment => (ae_some_html params[:comment]))
    @workflow.comments << comment
    
    respond_to do |format|
      format.html { render :partial => "comments/comments", :locals => { :commentable => @workflow, :add_url => comment_workflow_path(@workflow) } }
      format.xml { render :xml => @workflow.comments.to_xml }
    end
  end
  
  # DELETE /workflows/1;comment_delete
  # DELETE /workflows/1.xml;comment_delete
  def comment_delete
    if params[:comment_id]
      comment = Comment.find(params[:comment_id].to_i)
      # security checks:
      if comment.user_id == current_user.id and comment.commentable_type.downcase == 'workflow' and comment.commentable_id == @workflow.id
        comment.destroy
      end
    end
    
    respond_to do |format|
      format.html { render :partial => "comments/comments", :locals => { :commentable => @workflow, :add_url => comment_workflow_path(@workflow) } }
      format.xml { render :xml => @workflow.comments.to_xml }
    end
  end
  
  # POST /workflows/1;rate
  # POST /workflows/1.xml;rate
  def rate
    Rating.delete_all(["rateable_type = ? AND rateable_id = ? AND user_id = ?", @workflow.class.to_s, @workflow.id, current_user.id])
    
    @workflow.ratings << Rating.create(:user => current_user, :rating => params[:rating])
    
    respond_to do |format|
      format.html { 
        render :update do |page|
          page.replace_html "ratings_inner", :partial => "contributions/ratings_box_inner", :locals => { :contributable => @workflow, :controller_name => controller.controller_name }
          page.replace_html "ratings_breakdown", :partial => "contributions/ratings_box_breakdown", :locals => { :contributable => @workflow }
        end }
      format.xml { render :xml => @rateable.ratings.to_xml }
    end
  end
  
  # POST /workflows/1;tag
  # POST /workflows/1.xml;tag
  def tag
    @workflow.user_id = current_user # acts_as_taggable_redux
    @workflow.tag_list = "#{@workflow.tag_list}, #{convert_tags_to_gem_format params[:tag_list]}" if params[:tag_list]
    @workflow.update_tags # hack to get around acts_as_versioned
    
    respond_to do |format|
      format.html { render :partial => "contributions/tags_box_inner", :locals => { :contributable => @workflow } }
      format.xml { render :xml => @workflow.tags.to_xml }
    end
  end
  
  # GET /workflows/1;download
  # GET /workflows/1.xml;download
  def download
    @download = Download.create(:contribution => @workflow.contribution, :user => (logged_in? ? current_user : nil))
    
    send_data(@workflow.scufl, :filename => @workflow.unique_name + ".xml", :type => "text/xml")
  end
  
  # GET /workflows
  # GET /workflows.xml
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @workflows.to_xml }
      format.rss do
        #@workflows = Workflow.find(:all, :order => "updated_at DESC") # list all (if required)
        render :action => 'index.rxml', :layout => false
      end
    end
  end
  
  # GET /workflows/all
  def all
    respond_to do |format|
      format.html # all.rhtml
    end
  end

  # GET /workflows/1
  # GET /workflows/1.xml
  def show
    @viewing = Viewing.create(:contribution => @workflow.contribution, :user => (logged_in? ? current_user : nil))

    @sharing_mode  = determine_sharing_mode(@workflow)
    @updating_mode = determine_updating_mode(@workflow)
    
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @workflow.to_xml }
    end
  end

  # GET /workflows/new
  def new
    @workflow = Workflow.new

    @sharing_mode  = 1
    @updating_mode = 6
  end

  # GET /workflows/1;new_version
  def new_version
  end

  # GET /workflows/1;edit
  def edit
    @sharing_mode  = determine_sharing_mode(@workflow)
    @updating_mode = determine_updating_mode(@workflow)
  end

  # POST /workflows
  # POST /workflows.xml
  def create

    params[:workflow][:contributor_type], params[:workflow][:contributor_id] = "User", current_user.id
    
    # create workflow using helper methods
    @workflow = create_workflow(params[:workflow])
    
    respond_to do |format|
      if @workflow.save
        if params[:workflow][:tag_list]
          @workflow.user_id = current_user
          @workflow.tag_list = convert_tags_to_gem_format params[:workflow][:tag_list]
          @workflow.update_tags
        end
                
        @workflow.contribution.update_attributes(params[:contribution])

        update_policy(@workflow, params)
        
        # Credits and Attributions:
        update_workflow_credits(@workflow, params)
        update_workflow_attributions(@workflow, params)

        flash[:notice] = 'Workflow was successfully created.'
        format.html { redirect_to workflow_url(@workflow) }
        format.xml  { head :created, :location => workflow_url(@workflow) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @workflow.errors.to_xml }
      end
    end
  end

  # PUT /workflows/1
  # PUT /workflows/1.xml
  def update

    # remove protected columns
    if params[:workflow]
      [:contributor_id, :contributor_type, :image, :created_at, :updated_at, :version].each do |column_name|
        params[:workflow].delete(column_name)
      end
    end
    
    # remove owner only columns
    unless @workflow.contribution.owner?(current_user)
      [:unique_name, :license].each do |column_name|
        params[:workflow].delete(column_name)
      end
    end
    
    # update contributor with 'latest' uploader (or "editor")
    #params[:workflow][:contributor_type], params[:workflow][:contributor_id] = "User", current_user.id
    
    respond_to do |format|
      scufl = params[:workflow][:scufl]
      
      # hack to only update the workflow version table if the scufl has been altered
      unless scufl.nil?
        # create new scufl model
        scufl_model = Scufl::Parser.new.parse(scufl.read)
        scufl.rewind
        
        unless RUBY_PLATFORM =~ /mswin32/
          # create new diagrams and append new version number to filename
          img, svg = create_workflow_diagrams(scufl_model, "#{@workflow.unique_name}_#{@workflow.version.to_i + 1}")
          
          @workflow.image, @workflow.svg, @workflow.scufl = img, svg, scufl.read
        end
        
        params[:workflow].delete("scufl") # remove scufl attribute from received workflow parameters
        
        # REPEATED CODE
        # See line 207
        if @workflow.update_attributes(params[:workflow])
          if params[:workflow][:tag_list]
            refresh_tags(@workflow, params[:workflow][:tag_list], current_user)
          end
        
          # security fix (only allow the owner to change the policy)
          @workflow.contribution.update_attributes(params[:contribution]) if @workflow.contribution.owner?(current_user)
        
          flash[:notice] = 'Workflow was successfully updated.'
          format.html { redirect_to workflow_url(@workflow) }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @workflow.errors.to_xml }
        end
        # END REPEATED CODE
      else
        Workflow.without_revision do 
          
      if @workflow.update_attributes(params[:workflow])
        if params[:workflow][:tag_list]
          refresh_tags(@workflow, params[:workflow][:tag_list], current_user)
        end
        
        # security fix (only allow the owner to change the policy)
        @workflow.contribution.update_attributes(params[:contribution]) if @workflow.contribution.owner?(current_user)
        
        if ((params[:sharing] != nil) and (params[:updating] != nil))
          update_policy(@workflow, params)
        end

        update_workflow_credits(@workflow, params)
        update_workflow_attributions(@workflow, params)

        flash[:notice] = 'Workflow was successfully updated.'
        format.html { redirect_to workflow_url(@workflow) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @workflow.errors.to_xml }
      end
          
        end
      end
    end
  end

  # DELETE /workflows/1
  # DELETE /workflows/1.xml
  def destroy
    @workflow.destroy

    respond_to do |format|
      format.html { redirect_to workflows_url }
      format.xml  { head :ok }
    end
  end
  
protected

  def find_workflows
    login_required if login_available?
    
    found = Workflow.find(:all, 
                          construct_options.merge({:page => { :size => 20, :current => params[:page] }}))
    
    found.each do |workflow|
      workflow.scufl = nil unless workflow.authorized?("download", (logged_in? ? current_user : nil))
    end
    
    @workflows = found
  end
  
  def find_workflow_auth
    begin
      # attempt to authenticate the user before you return the workflow
      login_required if login_available?
    
      workflow = Workflow.find(params[:id])
      
      if workflow.authorized?(action_name, (logged_in? ? current_user : nil))
        if params[:version]
          @latest_version = workflow.versions.length
          if workflow.revert_to(params[:version])
            @workflow = workflow
          else
            error("Version not found (is invalid)", "not found (is invalid)", :version)
          end
        else
          @workflow = workflow
        end
        
        # remove scufl from workflow if the user is not authorized for download
        @workflow.scufl = nil unless @workflow.authorized?("download", (logged_in? ? current_user : nil))
      else
        if logged_in?
          error("Workflow not found (id not authorized)", "is invalid (not authorized)")
        else
          find_workflow_auth if login_required
        end
      end
    rescue ActiveRecord::RecordNotFound
      error("Workflow not found", "is invalid")
    end
  end
  
  def create_workflow(wf)
    scufl_model = Scufl::Parser.new.parse(wf[:scufl].read)
    wf[:scufl].rewind
    
    salt = rand 32768
    title, unique_name = scufl_model.description.title.blank? ? ["untitled", "untitled_#{salt}"] : [scufl_model.description.title,  "#{scufl_model.description.title.gsub(/[^\w\.\-]/,'_').downcase}_#{salt}"]
    
    rtn = Workflow.new(:scufl => wf[:scufl].read, 
                       :contributor_id => wf[:contributor_id], 
                       :contributor_type => wf[:contributor_type],
                       :title => title,
                       :unique_name => unique_name,
                       :body => scufl_model.description.description,
                       :license => wf[:license])
                       
    rtn.image, rtn.svg = create_workflow_diagrams(scufl_model, unique_name) unless RUBY_PLATFORM =~ /mswin32/
    
    return rtn
  end
  
  def create_workflow_diagrams(scufl_model, unique_name)
    i = Tempfile.new("image")
    Scufl::Dot.new.write_dot(i, scufl_model)
    i.close(false)
    img = StringIO.new(`dot -Tpng #{i.path}`)
    svg = StringIO.new(`dot -Tsvg #{i.path}`)
    i.unlink
    img.extend FileUpload
    img.original_filename = "#{unique_name}.png"
    img.content_type = "image/png"
    svg.extend FileUpload
    svg.original_filename = "#{unique_name}.svg"
    svg.content_type = "image/svg+xml"
    
    return img, svg
  end

private

  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Workflow.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to workflows_url }
      format.xml { render :xml => err.to_xml }
    end
  end
  
  def construct_options
    valid_keys = ["contributor_id", "contributor_type"]
    
    cond_sql = ""
    cond_params = []
    
    params.each do |key, value|
      next if value.nil?
      
      if valid_keys.include? key
        cond_sql << " AND " unless cond_sql.empty?
        cond_sql << "#{key} = ?" 
        cond_params << value
      end
    end
    
    options = {:order => "updated_at DESC"}
    
    # added to faciliate faster requests for iGoogle gadgets
    # ?limit=0 returns all workflows (i.e. no limit!)
    options = options.merge({:limit => params[:limit]}) if params[:limit] and (params[:limit].to_i != 0)
    
    options = options.merge({:conditions => [cond_sql] + cond_params}) unless cond_sql.empty?
    
    options
  end

  def update_workflow_credits(workflow, params)
    
    # First delete old creditations:
    workflow.creditors.each do |c|
      c.destroy
    end
    
    # Then create new creditations:
    
    # Current user
    if (params[:credits_me].downcase == 'true')
      c = Creditation.new(:creditor_type => 'User', :creditor_id => current_user.id, :creditable_type => 'Workflow', :creditable_id => workflow.id)
      c.save
    end
    
    # Friends + other users
    user_ids = parse_comma_seperated_string(params[:credits_users])
    user_ids.each do |id|
      c = Creditation.new(:creditor_type => 'User', :creditor_id => id, :creditable_type => 'Workflow', :creditable_id => workflow.id)
      c.save
    end
    
    # Networks (aka Groups)
    network_ids = parse_comma_seperated_string(params[:credits_groups])
    network_ids.each do |id|
      c = Creditation.new(:creditor_type => 'Network', :creditor_id => id, :creditable_type => 'Workflow', :creditable_id => workflow.id)
      c.save
    end
    
  end
  
  def update_workflow_attributions(workflow, params)
    
    # First delete old attributions:
    workflow.attributors.each do |a|
      a.destroy
    end
    
    # Then create new attributions:
    
    attributor_ids = parse_comma_seperated_string(params[:attributions_workflows])
    
    # Note: currently only existing workflows can be used in attributions.
    # In future, it is likely that other types of files can be used (re: EMOs)
    attributor_type = 'Workflow'
    attributor_ids.each do |id|
      a = Attribution.new(:attributor_type => attributor_type, :attributor_id => id, :attributable_type => 'Workflow', :attributable_id  => workflow.id)
      a.save
    end
    
  end
  
end

module FileUpload
  attr_accessor :original_filename, :content_type
end
