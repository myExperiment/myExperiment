class ViewingsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  
  before_filter :find_viewings, :only => [:index]
  before_filter :find_viewing, :only => [:show]
  
  # GET /viewings
  # GET /contribution/1/viewings
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # GET /viewings/1
  # GET /contribution/1/viewings/1
  def show
    respond_to do |format|
      format.html # show.rhtml
    end
  end
  
  def new
    error("That action (viewings/new) has been disabled", "action has been disabled")
  end
  
  def create
    error("That action (viewings/create) has been disabled", "action has been disabled")
  end
  
  def edit
    error("That action (viewings/edit) has been disabled", "action has been disabled")
  end
  
  def update
    error("That action (viewings/update) has been disabled", "action has been disabled")
  end
  
  def destroy
    error("That action (viewings/new) has been disabled", "action has been disabled")
  end
  
protected

  def find_contribution
    if contribution = Contribution.find(:first, :conditions => ["id = ?", params[:contribution_id]])
      @contribution = contribution
    else
      error("Contribution ID not found", "not found", :contribution_id)
    end
  end

  def find_viewings
    if params[:contribution_id]
      find_contribution
      
      @viewings = Viewing.find(:all, 
                               :conditions => ["contribution_id = ?", @contribution.id],
                               :page => { :size => 20, 
                                          :current => params[:page] })
    else
      @viewings = Viewing.find(:all,
                               :page => { :size => 20, 
                                          :current => params[:page] })
    end
  end
  
  def find_viewing
    if params[:contribution_id]
      find_contribution
      
      viewing = Viewing.find(:first, :conditions => ["id = ? AND contribution_id = ?", params[:id], @contribution.id])
    else
      viewing = Viewing.find(:first, :conditions => ["id = ?", params[:id]])
    end
    
    if viewing
      @viewing = viewing
    else
      error("Viewing ID not found", "not found")
    end
  end
  
private

  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Viewing.new.errors).add(attr, message)
    
    respond_to do |format|
      if @contribution
        format.html { redirect_to viewings_url(@contribution) }
      else
        format.html { redirect_to contributions_url }
      end
    end
  end
end
