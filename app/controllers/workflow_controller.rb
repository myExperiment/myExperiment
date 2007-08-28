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

require "scufl/model"
require "scufl/parser"
require "scufl/dot"
require "tempfile"
require 'zip/zip'

class WorkflowController < ApplicationController

  before_filter :login_required, :except => [:index, :gimme]
  
  before_filter :only => [:show, :gimme, :bookmark, :tag] do |w|
    w.record_in_history(w.params)
  end

  layout  'application', :except => [:textify, :live_search]

  auto_complete_for :tag, :name

  before_filter :only => [:show, :rate, :comment, :tag, :bookmark, :textify, :download, :gimme] do |w|
    w.find_workflow # default parameter is "r"
  end

  before_filter :only => [:edit, :workflow, :update] do |w|
    w.find_workflow("m")
  end

  before_filter :only => [:sharing, :update_sharing, :create_shared_user, :create_shared_project, :destroy_shared_user, :destroy_shared_project, :destroy] do |w|
    w.find_workflow("d")
  end

  def index
    redirect_to :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
                           :redirect_to => { :action => :list }

  def find_workflow(permission = "r")
    if params[:id]
      begin
        workflow = Workflow.find(params[:id])
        
        if logged_in?
          if workflow.authorized? current_user, permission
            @workflow = workflow
          else
            flash[:notice] = "You are not authorized to access the workflow titled '#{workflow.title.capitalize}'"
            redirect_to :action => :list
          end
        else
          if workflow.acl_r.to_i == 8
            @workflow = workflow
          else
            login_required
          end
        end
      rescue ActiveRecord::RecordNotFound
        flash[:notice] = "The workflow with identifier ##{params[:id]} was not found"
        redirect_to :action => :list
      end
    else
      flash[:notice] = "The workflow identifier ##{params[:id]} is invalid"
      redirect_to :action => :list
    end
  end

  def new

  end

  def show

  end

  def edit

  end

  def live_search

  end
  
  def most
    case (@pivot = params[:id] || "viewed")
      when "bookmarked" then action = "bookmark"
      when "downloaded" then action = "gimme"
      when "tagged" then action = "tag"
      when "viewed" then action = "show"
      else redirect_to :action => :list
    end
      
    query_results, @updated_at = query_history("workflow", action)
    
    if query_results.empty?
      redirect_to :action => :list
    end
    
    @workflows, @counts = [], []
    query_results.each do |count, params_id|
      @workflows << Workflow.find(params_id)
      @counts << count
    end
    
    @workflow_pages, @workflows = paginate_collection @workflows, :page => params[:page]
    @count_pages, @counts = paginate_collection @counts, :page => params[:page]
    
    # paginate @workflows and @counts goes here!!
    # this leaves the question.. is it right to have a History entity?
    # why not just store one integer for each pivot and increment
    # this would allow for paginated finds!
  end

  def list
    @workflows = Workflow.find(:all, :order => "created_at DESC", :limit => 50,
                               :page => {:size => 15, :current => params[:page], :first => 1})
  end

  def results
    @query = params[:id]
    @collection = Workflow.find_tagged_with(@query, :page => {:size => 15, :current => params[:page], :first => 1})
  end

  def search
    unless params[:query].blank?
      @query = params[:query]
      #params[:searchtext] = sanitize(params[:searchtext])
      params[:page] = 1 unless params[:page]

      s = Ferret::Search::SortField.new(:rating, :reverse => true)
      @collection = Workflow.ferret_find(@query, {:page => {:size => 10, :current => params[:page], :first => 1}, :sort => s})
      render :action => 'results'
    else
      @collection = Workflow.find(:all, :page => {:size => 10, :current => params[:page], :first => 1})
      render :action => 'results'
    end
  end

  # START Sharing and Naming stuff..

  def sharing
    @shared_users = SharingUser.find(:all, :conditions => [ "workflow_id = ?", @workflow.id ])

    @unauth_users = []
    User.find(:all).each do |u|
      @unauth_users << u unless (@workflow.sharing_user? u or @workflow.owner? u)
    end

    @shared_projects = SharingProject.find(:all, :conditions => [ "workflow_id = ?", @workflow.id])

    @unauth_projects = []
    Project.find(:all).each do |p|
      @unauth_projects << p unless @workflow.sharing_project? p
    end

    @menu = { "0 - Owner only" => 0,
              "1 - Shared Projects only" => 1,
              "2 - Shared Users only" => 2,
              "3 - Shared Users and Projects only" => 3,
              "4 - Friends only" => 4,
              "5 - Friends and Shared Projects only" => 5,
              "6 - Friends and Shared Users only" => 6,
              "7 - Friends, Shared Users and Projects only" => 7,
              "8 - Public (all)" => 8 }
  end

  def update_sharing
    # calculate new acl value from check boxes
    total = 0
    total += 1 if params[:sharing_projects].to_i == 1
    total += 2 if params[:sharing_users].to_i == 2
    total += 4 if params[:friends].to_i == 4
    total = 8 if params[:everybody].to_i == 8
    # ensures valid total (0 <= total <= 8)

    if @workflow.update_attribute :acl_r, total and @workflow.update_attribute :license, params[:license]
      flash[:notice] = "Sharing was successfully updated."
      redirect_to :action => :show, :id => @workflow
    else
      render :action => :new
    end
  end

  def create_shared_user
    @shared_user = SharingUser.new
    @shared_user.user_id = params[:user_id]
    @shared_user.workflow_id = @workflow.id
    if @shared_user.save
      flash[:notice] = "Shared User was successfully created!"
      redirect_to :action => :sharing, :id => @workflow.id
    else
      render :action => :new
    end
  end

  def destroy_shared_user
    SharingUser.find(params[:shared_user_id]).destroy
    flash[:notice] = "Shared User was successfully removed!"
    redirect_to :action => :sharing, :id => @workflow.id
  end

  def create_shared_project
    @shared_project = SharingProject.new
    @shared_project.project_id = params[:project_id]
    @shared_project.workflow_id = @workflow.id
    if @shared_project.save
      flash[:notice] = "Shared Project was successfully created!"
      redirect_to :action => :sharing, :id => @workflow.id
    else
      render :action => :new
    end
  end

  def destroy_shared_project
    SharingProject.find(params[:shared_project_id]).destroy
    flash[:notice] = "Shared Project was successfully removed!"
    redirect_to :action => :sharing, :id => @workflow.id
  end

  # END Sharing and Naming stuff

  def rate
    @rateable = Workflow.find(params[:id])
    Rating.delete_all(["rateable_type = 'Workflow' AND rateable_id = ? AND user_id = ?",
    params[:id], session[:user_id]])
    @rateable.add_rating Rating.new(:rating => params[:rating], :user_id => session[:user_id])
    @rateable.save
    render :action => '../rating/rate'
  end

  def comment
    @comment = Comment.new(:comment => params[:comment], :user_id => session[:user_id])
    @workflow.add_comment @comment
    render :partial => 'comment'
  end

  def tag
    tags = params[:tag][:name]
    @workflow.update_attributes(:tag_list => "#{@workflow.tag_list}, #{tags}")
    render :partial => 'tags'
  end

  def bookmark
    @workflow.bookmarks << Bookmark.new(:user_id => session[:user_id])
    flash[:notice] = 'Workflow added to your bookmarks'
    render :action => 'show', :id => @workflow
  end

  def update
    if @workflow.update_attributes(params[:workflow])
      flash[:notice] = 'Workflow was successfully updated.'
      redirect_to :action => 'show', :id => @workflow
    else
      render :action => 'edit'
    end
  end

  def destroy
    @workflow.destroy
    redirect_to :action => 'list'
  end

  def download

  end

  def gimme
    send_file(@workflow.scufl,
              :filename     =>  File.basename(@workflow.scufl),
              :type         =>  'application/octet-stream')
  end

  def textify
    @temp_file = Tempfile.new('image')

    File.open("#{@workflow.scufl}", "r") do |f|
      f.read(@temp_file.read)
    end

    return @temp_file
  end

  def create
    if params[:workflow] and params[:workflow][:scufl] and not params[:workflow][:scufl].blank?
      parser = Scufl::Parser.new
      scufl_model = parser.parse(params[:workflow][:scufl].read)

      params[:workflow][:scufl].rewind

      params[:workflow][:image] = get_image(scufl_model, params[:workflow][:scufl].original_filename)
      if scufl_model.description.title.blank?
        params[:workflow][:title] = '(untitled workflow)'
      else
        params[:workflow][:title] = scufl_model.description.title
      end
      params[:workflow][:description] = scufl_model.description.description

      @workflow = Workflow.new(params[:workflow])
      @workflow.user_id = session[:user_id]
      if @workflow.save
        flash[:notice] = 'Thanks for uploading your workflow.'
        redirect_to :action => 'edit', :id => @workflow
      else
        flash[:notice] = 'Error uploading workflow.'
        render :action => 'new'
      end
    else
      flash[:notice] = 'Enter a workflow file to upload.'
      render :action => 'new'
    end
  rescue
    flash[:notice] = "#{params[:workflow][:scufl].original_filename} is not a valid workflow file."
    render :action => 'new'
  end

  def upload
    current_file = ''
    if params[:zip]
      unless params[:zip].blank?
        zip_found = false
        Zip::ZipInputStream::open(params[:zip].path) { |io|
          while (entry = io.get_next_entry)
            zip_found = true
            current_file = entry.name
            create_workflow(io, entry.name)
          end
        }
        if not zip_found
          flash[:notice] = "#{params[:zip].original_filename} is not a zip file"
        else
          redirect_to :action => 'list'
        end
      else
        flash[:notice] = 'Specify a zip file to upload.'
      end
    end
  rescue
    flash[:notice] = "#{current_file} is not a valid workflow file."
  end

private

  def create_workflow(scufl, name = nil)
    scuflFile = StringIO.new(scufl.read)
    scuflFile.extend FileUpload

    name = "workflow.xml" if name == nil

    scuflFile.original_filename = name
    scuflFile.content_type = "text/xml"

    workflow = { :scufl => scuflFile }
    parser = Scufl::Parser.new
    scufl_model = parser.parse(workflow[:scufl].read)

    workflow[:scufl].rewind

    workflow[:image] = get_image(scufl_model, workflow[:scufl].original_filename)
    if scufl_model.description.title.blank?
      workflow[:title]  = '(untitled workflow)'
    else
      workflow[:title] = scufl_model.description.title
    end
    workflow[:description] = scufl_model.description.description

    @workflow = Workflow.new(workflow)
    @workflow.user_id = session[:user_id]
    @workflow.save
  end

  def get_image(model, filename)
    dot = Scufl::Dot.new

    # create temp file
    tmpDotFile = Tempfile.new("image")

    # write dot to temp file
    dot.write_dot(tmpDotFile, model)
    tmpDotFile.close

    # call out to dot to create the image
    img = StringIO.new(`dot -Tpng #{tmpDotFile.path}`)

    # delete the temporary file
    tmpDotFile.delete

    img.extend FileUpload

    if filename
      img.original_filename = filename.split('.')[0] + ".png"
    else
      img.original_filename = "workflow.png"
    end
    img.content_type = "image/png"

    return img
  end
  
protected

    def openid_consumer
      @openid_consumer ||= OpenID::Consumer.new(session,      
        OpenID::FilesystemStore.new("#{RAILS_ROOT}/tmp/openid"))
    end

end

module FileUpload
  attr_accessor :original_filename, :content_type
end
