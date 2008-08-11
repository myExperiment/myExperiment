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
  
  before_filter :invalidate_listing_cache, :only => [ :create, :update, :destroy ]
  
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  def show
    respond_to do |format|
      format.html # show.rhtml
    end
  end

  def new
    @review = Review.new
    @review.reviewable = @reviewable
    @review.user_id = current_user.id
    respond_to do |format|
      format.html # new.rhtml
    end
  end

  def create
    @review = Review.new(params[:review])
    @review.reviewable = @reviewable
    @review.user_id = current_user.id
    
    respond_to do |format|
      if @review.save
        update_rating(@review, params[:rating])
        flash[:notice] = 'Thank you for your review!'
        format.html { redirect_to review_url(@reviewable, @review) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html # edit.rhtml
    end
  end

  def update
    respond_to do |format|
      if @review.update_attributes(params[:review])
        update_rating(@review, params[:rating])
        flash[:notice] = 'Review was successfully updated.'
        format.html { redirect_to review_url(@reviewable, @review) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @review.destroy

    respond_to do |format|
      flash[:notice] = 'Review was successfully deleted.'
      format.html { redirect_to reviews_url(@reviewable) }
    end
  end
  
protected

  def update_rating(review, rating_param)
    if ["1", "2", "3", "4", "5"].include?(rating_param)
      rating_val = rating_param.to_i
      if (rating = review.associated_rating)
        rating.rating = rating_val
        rating.save
      else
        rating = Rating.new(
          :rating => rating_val, 
          :user_id => review.user_id,
          :rateable_type => review.reviewable_type,
          :rateable_id => review.reviewable_id)
        rating.save
      end
    end
  end

  def find_reviewable_auth
    # IMPORTANT NOTE: currently the only reviewable supported is "Workflow".
    # See note at the beginning of this controller for more info.
 
    begin
      # attempt to authenticate the user before you return the reviewable
      login_required if login_available?
    
      workflow = Workflow.find(params[:workflow_id])
      
      if workflow.authorized?("show", (logged_in? ? current_user : nil))
        # remove scufl from workflow if the user is not authorized for download
        workflow.content_blob.data = nil unless workflow.authorized?("download", (logged_in? ? current_user : nil))
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
      error("Review not found or action not authorized", "is invalid (not authorized)")
    end
  end
  
  def invalidate_listing_cache
    if @reviewable
      expire_fragment(:controller => 'workflows_cache', :action => 'listing', :id => @reviewable.id)
    end
  end

private

  def error(notice, message, attr=:id)
    flash[:error] = notice
    (err = Review.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to reviews_url(params[:workflow_id]) }
    end
  end
end
