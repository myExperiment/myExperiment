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
    if logged_in?
      from_user = params[:from].blank? ? current_user.name : params[:from]
      from_user += ' (' + (!params[:email].blank? ? params[:email] : 'no email') + ')'
      Mailer.deliver_feedback(from_user, params[:subject], params[:content], current_user)
      
      respond_to do |format|
        flash[:notice] = 'Your feedback has been submitted. Thank you very much.'
        format.html { redirect_to "/feedback" }
      end
    else
      if captcha_valid?(params[:feedback][:captcha_id], params[:feedback][:captcha_validation])
    
        from_user = params[:from] + ' (' + (!params[:email].blank? ? params[:email] : 'no email') + ')';
        Mailer.deliver_feedback(from_user, params[:subject], params[:content])
    
        respond_to do |format|
          flash[:notice] = 'Your feedback has been submitted. Thank you very much.'
          format.html { redirect_to "/feedback" }
        end
      else
        respond_to do |format|
          flash[:error] = 'Your feedback has not been submitted. CAPTCHA was not entered correctly.'
          format.html { redirect_to "/feedback?from="+params[:from]+"&email="+params[:email]+"&subject="+params[:subject]+"&content="+params[:content] }
        end
      end
    end
  end
  
private

  def only_index
    redirect_to :action => :index
  end
end
