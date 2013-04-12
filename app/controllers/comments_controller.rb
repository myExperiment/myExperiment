# myExperiment: app/controllers/comments_controller.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

class CommentsController < ApplicationController
  
  before_filter :find_context, :only => [ :create, :index, :timeline ]
  before_filter :find_comment, :only => [ :destroy ]

  # GET /:context_type/:context_id/comments
  def index
    if params[:start] && params[:end]
      begin
        @comments = Comment.find(:all, :conditions => [ "commentable_id = ? AND commentable_type = ? AND created_at > ? AND created_at < ?", @context.id, @context.class.name, params[:start].to_time, params[:end].to_time ] )
      rescue TypeError, ArgumentError
      end
    end
    @comments ||= []
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
      comment = Comment.new(:user => current_user, :comment => text, :commentable => @context)

      success = comment.save

      if success
        Activity.create(:subject => current_user, :action => 'create', :objekt => comment, :auth => @context)
        @context.solr_index if @context.respond_to?(:solr_index)
      end
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
    @context.solr_index if @context.respond_to?(:solr_index)
    
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

  def find_comment
    @comment = Comment.find_by_id(params[:id])
    @context = @comment.commentable

    if @comment.nil?
      render_404("Comment not found.")
    elsif !Authorization.check('view', @context, current_user)
      render_401("You are not authorized to delete this comment.")
    end
  end

  def find_context
    @context = extract_resource_context(params)

    if @context.nil?
      render_404("Comment context not found.")
    elsif !Authorization.check('view', @context, current_user)
      render_401("You are not authorized to view this resource's comments.")
    end
  end
end
