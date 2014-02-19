# myExperiment: app/controllers/home_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class HomeController < ApplicationController
  
  # GET /home
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  def front_page
    respond_to do |format|
      if logged_in?
        format.html { redirect_to home_url }
      else
        format.html { render :file => 'public/front_page.html', :layout => false }
      end
    end
  end
  
end
