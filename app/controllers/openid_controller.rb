gem 'ruby-openid'

require 'openid'
require 'openid/store/filesystem'


# http://www.danwebb.net/2007/2/27/the-no-shit-guide-to-supporting-openid-in-your-applications
class OpenidController < ApplicationController
  before_filter :login_required

  def new
    # show form asking for new openid
  end

  def create
    openid_url = params[:openid_url]
    begin
      response = consumer.begin(openid_url)

      return_to = url_for(:action=> 'complete')
      trust_root = url_for(:controller=>'')
      
      url = response.redirect_url(trust_root, return_to, true) # <== immediate mode
      redirect_to(url)
      return
    rescue OpenID::DiscoveryFailure
      flash[:error] = "Couldn't find an OpenID for that URL"
    rescue RuntimeError, Timeout::Error => e
      if e.class == Timeout::Error
        flash[:error] = "Could not contact your OpenID server."
      else
        flash[:error] = "An unknown error occurred whilst contacting your OpenID server."
      end
    end
    render :action => :new
  end

  def complete
    current_url = url_for(:action => 'complete', :only_path => false)
    parameters = params.reject{|k,v|request.path_parameters[k]}

    response = consumer.complete(parameters, current_url)

    case response.status
      when OpenID::Consumer::SUCCESS, OpenID::Consumer::SETUP_NEEDED
        current_user.openid_url = response.identity_url
        if current_user.save
          redirect_to user_path(current_user)
          return
        else
          flash[:error] = "OpenID already registered to another #{Conf.sitename} account"
        end
        
      # In immediate mode, we shouldnt wont get these responses, but just in
      # case..
      when OpenID::Consumer::FAILURE
        if response.display_identifier
          flash[:error] = "Verification of #{response.display_identifier} failed: #{response.message}"
        else
          flash[:error] = "Verification failed: #{response.message}"
        end
        redirect_to new_openid_url
      when OpenID::Consumer::CANCEL
          flash[:error] = "OpenID transaction cancelled"
    end
    redirect_to new_openid_url
  end

protected
  
  # Get the OpenID::Consumer object.
  def consumer
    # create the OpenID store for storing associations and nonces,
    # putting it in your app's db directory
    store_dir = Pathname.new(RAILS_ROOT).join('db').join('openid-store')
    store = OpenID::Store::Filesystem.new(store_dir)

    return OpenID::Consumer.new(session, store)
  end
end
