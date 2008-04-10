class DownloadsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  
  before_filter :find_downloads, :only => [:index]
  before_filter :find_download, :only => [:show]
  
  # GET /downloads
  # GET /contribution/1/downloads
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # GET /downloads/1
  # GET /contribution/1/downloads/1
  def show
    respond_to do |format|
      format.html # show.rhtml
    end
  end
  
  def new
    error("That action (downloads/new) has been disabled", "action has been disabled")
  end
  
  def create
    error("That action (downloads/create) has been disabled", "action has been disabled")
  end
  
  def edit
    error("That action (downloads/edit) has been disabled", "action has been disabled")
  end
  
  def update
    error("That action (downloads/update) has been disabled", "action has been disabled")
  end
  
  def destroy
    error("That action (downloads/new) has been disabled", "action has been disabled")
  end
  
protected

  def find_contribution
    if contribution = Contribution.find(:first, :conditions => ["id = ?", params[:contribution_id]])
      @contribution = contribution
    else
      error("Contribution ID not found", "not found", :contribution_id)
    end
  end

  def find_downloads
    if params[:contribution_id]
      find_contribution
      
      @downloads = Download.find(:all, 
                                 :conditions => ["contribution_id = ?", @contribution.id],
                                 :page => { :size => 20, 
                                            :current => params[:page] })
    else
      @downloads = Download.find(:all,
                                 :page => { :size => 20, 
                                            :current => params[:page] })
    end
  end
  
  def find_download
    if params[:contribution_id]
      find_contribution
      
      download = Download.find(:first, :conditions => ["id = ? AND contribution_id = ?", params[:id], @contribution.id])
    else
      download = Download.find(:first, :conditions => ["id = ?", params[:id]])
    end
    
    if download
      @download = download
    else
      error("Download ID not found", "not found")
    end
  end
  
private

  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Download.new.errors).add(attr, message)
    
    respond_to do |format|
      if @contribution
        format.html { redirect_to downloads_url(@contribution) }
      else
        format.html { redirect_to contributions_url }
      end
    end
  end
end
