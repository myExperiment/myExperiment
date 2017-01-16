# myExperiment: app/controllers/bookmarks_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class BookmarksController < ApplicationController
  before_filter :login_required
  
  before_filter :find_bookmark_auth, :only => [:show, :edit, :update, :destroy]

  # declare sweepers and which actions should invoke them
  cache_sweeper :bookmark_sweeper, :only => [ :destroy ]
  
  # GET /bookmarks
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end
  
  # GET /bookmarks/1
  def show
    respond_to do |format|
      format.html # show.rhtml
    end
  end
  
  # DELETE /bookmarks/1
  def destroy
    @bookmark.destroy

    respond_to do |format|
      format.html { redirect_to bookmarks_path }
    end
  end
  
protected

  def find_bookmark_auth
    if (@bookmark = Bookmark.find_by_id(params[:id], :conditions => ["user_id = ?", current_user.id])).nil?
      render_404("Bookmark not found.")
    end
  end
end
