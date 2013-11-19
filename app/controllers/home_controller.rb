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
        @title = "Personal feed"
        @id = @resource = home_url
        @entries = activities_for_feed(:user => current_user, :no_combine => true)

        unless @entries.empty? || @entries.last.empty?
          @updated = @entries.last.last.timestamp.to_datetime.rfc3339
        end

        render "activities/feed.atom"
      }
    end
  end
  
end
