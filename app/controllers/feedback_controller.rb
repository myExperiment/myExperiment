require 'recaptcha'

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
      Mailer.feedback(from_user, params[:subject], params[:content]).deliver #, current_user)
      
      respond_to do |format|
        flash[:notice] = 'Your feedback has been submitted. Thank you very much.'
        format.html { redirect_to "/feedback" }
      end
    else
      if Conf.recaptcha_enable && !verify_recaptcha(:private_key => Conf.recaptcha_private)
        respond_to do |format|
          flash[:error] = 'Your feedback has not been submitted. CAPTCHA was not entered correctly.'
          format.html { redirect_to "/feedback?from="+String(params[:from])+"&email="+String(params[:email])+"&subject="+String(params[:subject])+"&content="+String(params[:content]) }
        end
      else
        from_user = ( params[:from].blank? ? 'no from': params[:from] ) + ' (' + (!params[:email].blank? ? params[:email] : 'no email') + ')';
        Mailer.feedback(from_user, params[:subject], params[:content]).deliver
    
        respond_to do |format|
          flash[:notice] = 'Your feedback has been submitted. Thank you very much.'
          format.html { redirect_to "/feedback" }
        end
      end
    end
  end
  
private

  def only_index
    redirect_to :action => :index
  end
end
