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
    @bookmarks = Bookmark.find(:all, :conditions => ["user_id = ?", current_user.id], :order => "created_at DESC")
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
