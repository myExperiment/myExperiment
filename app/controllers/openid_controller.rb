gem 'ruby-openid'

# http://www.danwebb.net/2007/2/27/the-no-shit-guide-to-supporting-openid-in-your-applications
class OpenidController < ApplicationController
  before_filter :login_required

  def new
    # show form asking for new openid
  end

  def create
    openid_url = params[:openid_url]
    response = consumer.begin openid_url

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
    response = consumer.complete params

    case response.status
      when OpenID::SUCCESS
        current_user.openid_url = response.identity_url
        if current_user.save
          redirect_to user_path(current_user)
        else
          flash[:error] = "OpenID already registered to another #{Conf.sitename} account"
          redirect_to new_openid_url
        end
        
        return
      when OpenID::SETUP_NEEDED
        redirect_to response.setup_url # <== here!
        return
    end

    flash[:error] = 'Could not log on with your OpenID'
    redirect_to new_openid_url
  end

protected
  
  # Get the OpenID::Consumer object.
  def consumer
    # create the OpenID store for storing associations and nonces,
    # putting it in your app's db directory
    store_dir = Pathname.new(RAILS_ROOT).join('db').join('openid-store')
    store = OpenID::FilesystemStore.new(store_dir)

    return OpenID::Consumer.new(session, store)
  end
end
