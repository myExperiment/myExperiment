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

class BookmarksController < ApplicationController
  before_filter :login_required
  
  before_filter :find_bookmarks_auth, :only => [:index]
  before_filter :find_bookmark_auth, :only => [:show, :edit, :update, :destroy]
  
  # GET /bookmarks
  # GET /bookmarks.xml
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @bookmarks.to_xml }
    end
  end
  
  # GET /bookmarks/1
  # GET /bookmarks/1.xml
  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @bookmark.to_xml }
    end
  end
  
  # DELETE /bookmarks/1
  # DELETE /bookmarks/1.xml
  def destroy
    @bookmark.destroy

    respond_to do |format|
      format.html { redirect_to bookmarks_url }
      format.xml  { head :ok }
    end
  end
  
protected

  def find_bookmarks_auth
    @bookmarks = Bookmark.find(:all, 
                               :conditions => ["user_id = ?", current_user.id], 
                               :order => "created_at DESC",
                               :page => { :size => 20, 
                                          :current => params[:page] })
  end
  
  def find_bookmark_auth
    begin
      @bookmark = Bookmark.find(params[:id], :conditions => ["user_id = ?", current_user.id])
    rescue ActiveRecord::RecordNotFound
      error("Bookmark not found", "is invalid")
    end
  end
  
private

  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Bookmark.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to bookmarks_url }
      format.xml { render :xml => err.to_xml }
    end
  end
end
