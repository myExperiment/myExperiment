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
      begin
        @user = User.find(params[:user_id])
    
      rescue ActiveRecord::RecordNotFound
        error("User not found", "is invalid", :user_id)
      end
    else
      @user = User.find(params[:id])
    end
  end
end