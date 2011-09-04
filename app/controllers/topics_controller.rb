# -*- coding: undecided -*-
# myExperiment: app/controllers/topics_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class TopicsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  

  # declare sweepers and which actions should invoke them
  cache_sweeper :workflow_sweeper, :only => [ :create, :create_version, :launch, :update, :update_version, :destroy_version, :destroy ]
  cache_sweeper :download_viewing_sweeper, :only => [ :show, :download, :named_download, :launch ]
  cache_sweeper :permission_sweeper, :only => [ :create, :update, :destroy ]
  cache_sweeper :bookmark_sweeper, :only => [ :destroy, :favourite, :favourite_delete ]
  cache_sweeper :tag_sweeper, :only => [ :create, :update, :tag, :destroy ]
  cache_sweeper :comment_sweeper, :only => [ :comment, :comment_delete ]
  cache_sweeper :rating_sweeper, :only => [ :rate ]
  
  # These are provided by the Taverna gem
  require 'scufl/model'
  require 'scufl/parser'
  require 'scufl/dot'
 
  # GET /topics
  def index
    respond_to do |format|
      format.html do
		@curr_run = TopicRun.most_recent
      end
    end
  end
  
  def show
	respond_to do |format|
	  format.html do
	    @currtopic = Topic.find(params[:id])
	  end
	end  
  end
  
  def tag_feedback
    # Ensure that all the needed information was provided
    if params[:topic_id].blank? || params[:user_id].blank? || params[:tag_id].blank? || params[:score].blank?
      error("Malformed feedback information.", "")
    else
      this_topic = Topic.find(params[:topic_id]) rescue error("Invalid topic specified.")	
      #Ensure the feedback is for the current user
      if params[:user_id].to_i != current_user.id
        error("You may only post feedback as yourself.", "")
        return
      end
      # Not allowed to create duplicate feedback
      if this_topic.topic_tag_feedback.exists?( :user_id => params[:user_id], :tag_id => params[:tag_id] )
        error( "You may provide feedback only once per topic, tag pair.", "")
        return
      end
      #Create the feedback
      feedback = this_topic.topic_tag_feedback.build( :score => params[:score], :submit_dt => Time.new.utc )
      feedback.user = User.find(params[:user_id])
      feedback.tag = Tag.find(params[:tag_id])
      feedback.save
      #topic_id => params[:topic_id], :user_id => params[:user_id], :tag_id => params[:tag_id], 
         
      # What if the tag doesn't exist?
      
      respond_to do |response|
        # page.html {redirect_to topics_path }
        response.html {
          render :update  do |page|
            page.replace_html "tag_feedback_div_#{params[:topic_id]}_#{params[:tag_id]}", "Thanks!"
          end
        }
      end
    end
  end
  
  def topic_feedback
  	# Ensure that all the needed information was provided
    if params[:topic_id].blank? || params[:user_id].blank? || params[:score].blank?
      error("Malformed feedback information.", "")
    else
      this_topic = Topic.find(params[:topic_id]) rescue error("Invalid topic specified.")	
      #Ensure the feedback is for the current user
      if params[:user_id].to_i != current_user.id
        error("You may only post feedback as yourself.", "")
        return
      end
      # Not allowed to create duplicate feedback
      if this_topic.topic_feedback.exists?( :user_id => params[:user_id] )
        error( "You may provide feedback only once per topic.", "")
        return
      end
      #Create the feedback
      feedback = this_topic.topic_feedback.build( :score => params[:score], :submit_dt => Time.new.utc )
      feedback.user = User.find(params[:user_id])
      feedback.save
      
      respond_to do |response|
        # page.html {redirect_to topics_path }
        response.html {
          render :update  do |page|

            if
              this_topic.name.blank? 
            then
              topicName = "Explore this topic" 
            else
              topicName = this_topic.name 
            end

            topicLink = "<a href=\"#{topic_path(this_topic)}\">#{topicName}</a>"

            page.replace_html "topic_feedback_#{params[:topic_id]}", "#{topicLink} &nbsp;&nbsp;&nbsp;Thanks for your feedback!"
          end
        }
      end
    end
  end

private

  def error(notice, message, attr=:id)
    flash[:error] = notice
    (err = Workflow.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to topics_url }
    end
  end
  
end

