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

class PagesController < ApplicationController

  before_filter :login_required

  def edit
    @user = User.find(session[:user_id]);

    @page = Page.find_by_namespace_and_name(params[:id], params[:page])
    if not @page
#      @page = Page.new()
#      @page.name = params[:id]
#      @page.user = @user
#      @page.save
       flash[:notice] = 'Page not found'
       
    end
  end

  def update
    @page = Page.find_by_namespace_and_name(params[:id], params[:name])
    if params[:preview]
      @page.content = params[:page][:content]
      render :action => 'edit'
    else
      if @page.update_attributes(params[:page])
        flash[:notice] = 'Page was successfully updated.'
        if @page.pageable_type == 'Project'
          redirect_to "/projects/#{@page.namespace}"
        else
          redirect_to :action => 'show', :id => @page.namespace, :page => @page.name
        end
      else
        render :action => 'edit'
      end
    end
  end
  
  def show
    @page = Page.find_by_namespace_and_name(params[:id], params[:page])
    redirect_to(:action => 'edit', :id => params[:id], :page => params[:page]) if not @page
  end

end
