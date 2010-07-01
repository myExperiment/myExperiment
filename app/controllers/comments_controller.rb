# myExperiment: app/controllers/comments_controller.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

class CommentsController < ApplicationController
  
  before_filter :find_resource_context, :only => [ :create, :index, :timeline ]
  before_filter :find_resource, :only => [ :destroy ]

  # GET /:context_type/:context_id/comments
  def index
    @comments = Comment.find(:all, :conditions => [ "commentable_id = ? AND commentable_type = ? AND created_at > ? AND created_at < ?", @context.id, @context.class.name, params[:start].to_time, params[:end].to_time ] )
    respond_to do |format|
      format.json { render :partial => 'comments/timeline_json', :layout => false }
    end
  end

  # POST /:context_type/:context_id/comments
  def create 
    text = params[:comment][:comment]
    ajaxy = true
    
    if text.nil? or (text.length == 0)
      text = params[:comment_0_comment_editor]
      ajaxy = false
    end

    if text and text.length > 0
      comment = Comment.create(:user => current_user, :comment => text)
      @context.comments << comment
    end
    
    respond_to do |format|
      if ajaxy
        format.html { render :partial => "comments/comments", :locals => { :commentable => @context } }
      else
        format.html { redirect_to rest_resource_uri(@context) }
      end
    end
  end
  
  # DELETE /:context_type/:context_id/comments/:id
  def destroy
    @comment.destroy
    
    respond_to do |format|
      format.html { render :partial => "comments/comments", :locals => { :commentable => @context } }
    end
  end

  # GET /:context_type/:context_id/comments/timeline
  def timeline
    respond_to do |format|
      format.html # timeline.rhtml
    end
  end

  private

  def find_resource

    @context = extract_resource_context(params)
    @comment = Comment.find_by_id(params[:id])

    return false if @comment.nil? || @context.nil? || @comment.commentable != @context
    return false if Authorization.is_authorized?('view', nil, @context, current_user) == false
  end

  def find_resource_context

    @context = extract_resource_context(params)

    return false if @context.nil?
    return false if Authorization.is_authorized?('view', nil, @context, current_user) == false
  end
end

