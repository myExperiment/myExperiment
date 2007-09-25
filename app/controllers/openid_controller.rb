require_gem 'ruby-openid'

# http://www.danwebb.net/2007/2/27/the-no-shit-guide-to-supporting-openid-in-your-applications
class OpenidController < ApplicationController
  before_filter :login_required

  def new
    # show form asking for new openid
  end

  def create
    openid_url = params[:openid_url]
    response = openid_consumer.begin openid_url

    if response.status == OpenID::SUCCESS
      return_to = url_for(:action=> 'complete')
      trust_root = url_for(:controller=>'')
      
      redirect_url = response.redirect_url(trust_root, return_to, true) # <== immediate mode
      redirect_to redirect_url
      return
    end

    flash[:error] = "Couldn't find an OpenID for that URL"
    render :action => :new
  end

  def complete
    response = openid_consumer.complete params

    case response.status
      when OpenID::SUCCESS
        current_user.update_attribute(:openid_url, response.identity_url)
        redirect_to user_path(current_user)
        return
      when OpenID::SETUP_NEEDED
        redirect_to response.setup_url # <== here!
        return
    end

    flash[:error] = 'Could not log on with your OpenID'
    redirect_to new_openid_url
  end

protected
  
  def openid_consumer
      @openid_consumer ||= OpenID::Consumer.new(session,      
        OpenID::FilesystemStore.new("#{RAILS_ROOT}/tmp/openid"))
    end
end
