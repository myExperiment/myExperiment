# myExperiment: app/controllers/reviews_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class ReviewsController < ApplicationController
  
  # IMPORTANT NOTE: because of restrictions in the version of Rails used (v1.2.3),
  # polymorphic nested resources are not possible. So in the routes file, make sure
  # 'reviews' is only a nested resource of one top level resource.
  # Currently only Workflows can have reviews and this controller is Workflow specific! 

  before_filter :login_required, :except => [ :index, :show ]
  
  before_filter :find_reviewable_auth
  
  before_filter :find_reviews, :only => [ :index ]
  before_filter :find_review, :only => [ :show ]
  before_filter :find_review_auth, :only => [ :edit, :update, :destroy ]
  
  #after_filter :find_currentuser_rating, :only => [ :new ]
  before_filter :find_currentuser_rating, :only => [ :edit, :update ]
  
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @reviews.to_xml }
    end
  end

  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @review.to_xml }
    end
  end

  def new
    @review = Review.new
    @review.reviewable = @reviewable
    @review.user = current_user
  end

  def create
    @review = Review.new(params[:review])
    @review.reviewable = @reviewable
    @review.user = current_user
    
    # TODO: add creation of rating (if required).

    respond_to do |format|
      if @review.save
        flash[:notice] = 'Thank you for your review!'
        format.html { redirect_to review_url(@reviewable, @review) }
        format.xml  { head :created, :location => review_url(@reviewable, @review) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @review.errors.to_xml }
      end
    end
  end

  def edit
    @review = Review.find(params[:id])
  end

  def update
    respond_to do |format|
      if @review.update_attributes(params[:review])
        # TODO: add updating of rating, if required.
        flash[:notice] = 'Review was successfully updated.'
        format.html { redirect_to review_url(@reviewable, @review) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @review.errors.to_xml }
      end
    end
  end

  def destroy
    @review.destroy

    respond_to do |format|
      format.html { redirect_to review_url(@reviewable, @review) }
      format.xml  { head :ok }
    end
  end
  
protected

  def find_reviewable_auth
    # IMPORTANT NOTE: currently the only reviewable supported is "Workflow".
    # See note at the beginning of this controller for more info.
 
    begin
      # attempt to authenticate the user before you return the reviewable
      login_required if login_available?
    
      workflow = Workflow.find(params[:workflow_id])
      
      if workflow.authorized?("show", (logged_in? ? current_user : nil))
        # remove scufl from workflow if the user is not authorized for download
        workflow.scufl = nil unless workflow.authorized?("download", (logged_in? ? current_user : nil))
        @reviewable = workflow
      else
        if logged_in?
          error("Workflow not found (id not authorized)", "is invalid (not authorized)", :workflow_id)
        else
          find_reviewable_auth if login_required
        end
      end
    rescue ActiveRecord::RecordNotFound
      error("Workflow not found", "is invalid", :workflow_id)
    end
  end
  
  def find_reviews
    @reviews = @reviewable.reviews
  end
  
  def find_review
    if review = @reviewable.reviews.find(:first, :conditions => ["id = ?", params[:id]])
      @review = review
    else
      error("Review not found", "is invalid")
    end
  end
  
  def find_review_auth
    if review = @reviewable.reviews.find(:first, :conditions => ["id = ? AND user_id = ?", params[:id], current_user.id])
      @review = review
    else
      error("Review not found (id not authorized)", "is invalid (not authorized)")
    end
  end
  
  # Finds the rating made by the current user for the reviewable, if available.
  def find_currentuser_rating
    @rating = Rating.find(:first, :conditions => ["user_id = ? AND rateable_type = ? AND rateable_id = ?", current_user.id, @review.reviewable_type, @review.reviewable_id])
  end

private

  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Review.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to reviews_url(params[:workflow_id]) }
      format.xml { render :xml => err.to_xml }
    end
  end

end
