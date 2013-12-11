# myExperiment: app/controllers/home_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class HomeController < ApplicationController
  
  before_filter :login_required, :except => [:index]

  include ActivitiesHelper
  
  # GET /home
  def index
    respond_to do |format|
      format.html {
        # index.rhtml
      }

      format.atom {

        unless logged_in?
          render_401("")
          response.headers['WWW-Authenticate'] = "Basic realm=\"#{Conf.sitename}\""
          return
        end

        @title = "Personal feed"
        @id = @resource = home_url

        resources = current_user.personal_resources_and_subscriptions if logged_in?

        @entries = activities_for_feed(:contexts => resources,
            :user => current_user,
            :no_combine => true)

        unless @entries.empty? || @entries.last.empty?
          @updated = @entries.last.last.timestamp.to_datetime.rfc3339
        end

        render "activities/feed.atom"
      }
    end
  end
  
end
