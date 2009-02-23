# myExperiment: app/controllers/home_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class HomeController < ApplicationController
  
  before_filter :login_required, :except => [:index]
  
  # GET /home
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end
  
end
