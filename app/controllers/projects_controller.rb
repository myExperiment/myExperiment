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

class ProjectsController < ApplicationController
  
  before_filter :login_required
  
  def index
    redirect_to :action => 'list'
  end
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
  :redirect_to => { :action => :list }
  
  def list
    @projects = Project.find(:all, :page => {:size => 12, :current => params[:page], :first => 1})
  end
  
  def show
    @project = find_project(params[:id])
    if not @project.unique
      @unique_set = false
      @project.unique = @project.title.tr(' ', '_').downcase
#      @project = Project.find_by_unique(unique)
#      while @project
    else
      @unique_set = true    
    end
  end
  
  def new
    @project = Project.new
  end
  
  def create
    @project = Project.new(params[:project])
    @project.user_id = @user.id
    
    # Create Forum for each Project
    forum = Forum.new
    forum.name = @project.title.tr(' ', '_')
    forum.owner_id = @user.id;
    forum.save
    @project.forum_id = forum.id
    # Set Moderator for new Forum
    mod = Moderatorship.new
    mod.forum_id = forum.id
    mod.user_id = @user.id
    mod.save
    # End Create Forum for each Project
    
    if @project.save
      flash[:notice] = 'Project was successfully created.'
      
      page = Page.new()
      page.namespace = @project.id
      page.name = 'main'
      page.user_id = @user.id
      page.content = render_to_string :action => 'page_template', :layout => false
      @project.add_page(page)
      
      @membership = Membership.new()
      @membership.project_id = @project.id;
      @membership.user_id = @user.id
      @membership.save
      
    end
    
    redirect_to :action => 'show', :id => @project.id
  end
  
  def edit
    @project = find_project(params[:id])
    
    if not @project.user_id == session[:user_id]
      redirect_to :action => 'show', :id => @project.unique ? @project.unique : @project
    end
    
  end
  
  def update
    @project = Project.find(params[:id])
    if @project.update_attributes(params[:project])
      flash[:notice] = 'Project was successfully updated.'
      redirect_to :action => 'show', :id => @project.unique ? @project.unique : @project
    else
      render :action => 'edit'
    end
  end
  
  def unique
    @project = Project.find(params[:id])
    if @project.user_id == session[:user_id] and not @project.unique
      if @project.update_attributes(params[:project])
        for page in @project.find_pages_by_namespace(@project.id) do
          page.namespace = @project.unique
          page.save
        end
        flash[:notice] = 'Project name set.'
        redirect_to :action => 'show', :id => @project.unique
      else
        render :action => 'show', :id => @project
      end
    else
      redirect_to :action => 'show', :id => @project.unique ? @project.unique : @project
    end
  end
  
  def destroy
    Project.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
  def search
    unless params[:query].blank?
      @query = params[:query]
      #params[:searchtext] = sanitize(params[:searchtext])
      params[:page] = 1 unless params[:page]
      @collection = Project.ferret_find(@query, :page => {:size => 12, :current => params[:page], :first => 1})
      render :action => 'results'
    else
      @collection = Project.find(:all, :page => {:size => 12, :current => params[:page], :first => 1})
      render :action => 'results'
    end
  end
  
  auto_complete_for :profile, :name
  
#  def auto_complete_for_profile_name
#    auto_complete_responder_for_contacts params[:profile][:name]
#  end
  
  private
  
  def auto_complete_responder_for_contacts(value)
    @contacts = Profile.find(:all, 
                             :conditions => [ 'LOWER(name) LIKE ?',
    '%' + value.downcase + '%' ], 
    :order => 'name ASC',
    :limit => 8)
    render :partial => 'contacts'
  end
 
  def find_project(id)
    if id.to_i == 0
      Project.find_by_unique(id)
    else
      Project.find(id)
    end
  end
  
end
