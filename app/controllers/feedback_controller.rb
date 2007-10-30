class FeedbackController < ApplicationController
  before_filter :only_index, :except => :index
  
  def index
    # no instance variables
  end
  
private

  def only_index
    redirect_to :action => :index
  end
end
