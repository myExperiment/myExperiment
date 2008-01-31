class FeedbackController < ApplicationController
  before_filter :only_index, :except => [:index, :create]
  
  # GET /feedback
  def index
    
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # POST /feedback
  def create
    from_user = params[:from] + ' (' + (params[:email] ? params[:email] : 'no email') + ')';
    Mailer.deliver_feedback(from_user, params[:subject], params[:content])
    
    respond_to do |format|
      flash[:notice] = 'Your feedback has been submitted. Thank you very much.'
      format.html { redirect_to "/feedback" }
    end
  end
  
private

  def only_index
    redirect_to :action => :index
  end
end
