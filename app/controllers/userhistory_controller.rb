# myExperiment: app/controllers/userhistory_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class UserhistoryController < ApplicationController
  before_filter :login_required, :only => [:index]
  
  before_filter :find_user, :only => [:show]
  
  # GET /userhistory
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end
  
  # GET /users/1/userhistory
  # GET /userhistory/1
  def show
    respond_to do |format|
      format.html # show.rhtml
    end
  end
  
protected

  def find_user
    if params[:user_id]
      @user = User.find_by_id(params[:user_id])
    else
      @user = User.find_by_id(params[:id])
    end

    if @user.nil?
      render_404("User not found.")
    end
  end
end
