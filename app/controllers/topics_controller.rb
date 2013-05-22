# myExperiment: app/controllers/topics_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class TopicsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  before_filter :find_topic, :only => [:tag_feedback, :topic_feedback]

  # declare sweepers and which actions should invoke them
  cache_sweeper :workflow_sweeper, :only => [ :create, :create_version, :launch, :update, :update_version, :destroy ]
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
    this_topic = @topic

    # Not allowed to create duplicate feedback
    unless feedback = this_topic.topic_tag_feedback.find_by_user_id_and_tag_id(current_user.id, params[:tag_id])
      #Create the feedback
      feedback = this_topic.topic_tag_feedback.build( :score => params[:score], :submit_dt => Time.new.utc )
      feedback.user = current_user
      feedback.tag = Tag.find(params[:tag_id])
      feedback.save
    end

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
  
  def topic_feedback
    this_topic = @topic
    # Not allowed to create duplicate feedback
    unless feedback = this_topic.topic_feedback.find_by_user_id(current_user.id)
      #Create the feedback
      feedback = this_topic.topic_feedback.build( :score => params[:score], :submit_dt => Time.new.utc )
      feedback.user = current_user
      feedback.save
    end

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

          if feedback.score == 1
            img_url = 'images/thumbsup_grey.png'
          else
            img_url = 'images/thumbsdown_grey.png'
          end

          page.replace_html "topic_feedback_#{params[:topic_id]}", "<img src='#{img_url}'>"
        end
      }
    end
  end

private

  def find_topic
    @topic = Topic.find_by_id(params[:topic_id])

    if @topic.nil?
      render_404("Topic not found.")
    end
  end
end
