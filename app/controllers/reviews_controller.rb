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
  before_filter :find_review, :only => [ :show, :edit, :update, :destroy ]
  before_filter :auth_review, :only => [ :edit, :update, :destroy ]
  
  # declare sweepers and which actions should invoke them
  cache_sweeper :review_sweeper, :only => [ :create, :update, :delete ]
  
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  def show
    respond_to do |format|
      format.html {
        
        @lod_nir  = workflow_review_url(:id => @review.id, :workflow_id => @reviewable.id)
        @lod_html = workflow_review_url(:id => @review.id, :workflow_id => @reviewable.id, :format => 'html')
        @lod_rdf  = workflow_review_url(:id => @review.id, :workflow_id => @reviewable.id, :format => 'rdf')
        @lod_xml  = workflow_review_url(:id => @review.id, :workflow_id => @reviewable.id, :format => 'xml')
        
        # show.rhtml
      }

      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} reviews #{@review.id}`
        }
      end
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
        Activity.create(:subject => current_user, :action => 'create', :objekt => @review, :auth => @reviewable, :extra => params[:rating].to_i)
        update_rating(@review, params[:rating])
        flash[:notice] = 'Thank you for your review!'
        format.html { redirect_to workflow_review_path(@reviewable, @review) }
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
        Activity.create(:subject => current_user, :action => 'edit', :objekt => @review, :auth => @reviewable, :extra => params[:rating].to_i)
        update_rating(@review, params[:rating])
        flash[:notice] = 'Review was successfully updated.'
        format.html { redirect_to workflow_review_path(@reviewable, @review) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @review.destroy

    respond_to do |format|
      flash[:notice] = 'Review was successfully deleted.'
      format.html { redirect_to workflow_reviews_path(@reviewable) }
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
    @reviewable = Workflow.find_by_id(params[:workflow_id])

    if @reviewable.nil?
      render_404("Workflow not found.")
    elsif !Authorization.check('view', @reviewable, current_user)
      # remove workflow data from workflow if the user is not authorized for download
      render_401("You are not authorized to review this workflow.")
    else
      @reviewable.content_blob.data = nil unless Authorization.check('download', @reviewable, current_user)
    end
  end
  
  def find_reviews
    if @reviewable
      @reviews = @reviewable.reviews
    else
      @reviews = []
    end
  end
  
  def find_review
    if review = @reviewable.reviews.find(:first, :conditions => ["id = ?", params[:id]])
      @review = review
    else
      render_404("Review not found.")
    end
  end
  
  def auth_review
    unless @review.user == current_user
      render_401("You are not authorized to #{action_name} this review.")
    end
  end
end
