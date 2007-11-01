ActionController::Routing::Routes.draw do |map|
  # forums
  map.from_plugin :savage_beast
  
  # policy wizard
  map.resource :policy_wizard
  
  # mashup
  map.resource :mashup
  
  # search
  map.resource :search

  # tags and bookmarks
  map.resources :tags, :bookmarks

  # sessions and RESTful authentication
  map.resource :session
  
  # openid authentication
  map.resource :openid
  
  # all citations
  # map.resources :citations

  # all blobs (aka files)
  map.connect 'blobs/all', :controller => 'blobs', :action => 'all'

  # all users
  map.connect 'users/all', :controller => 'users', :action => 'all'

  # all networks (aka groups)
  map.connect 'networks/all', :controller => 'networks', :action => 'all'

  # all workflows
  map.connect 'workflows/all', :controller => 'workflows', :action => 'all'

  # workflows (downloadable)
  map.resources :workflows, :collection => { :search => :get }, :member => { :download => :get, :bookmark => :post, :comment => :post, :rate => :post, :tag => :post } do |workflow|
    # workflows have nested citations
    workflow.resources :citations
  end

  # blobs (downloadable)
  map.resources :blobs, :collection => { :search => :get }, :member => { :download => :get }

  # bloGs
  map.resources :blogs do |blog|
    # blogs have nested posts
    blog.resources :blog_posts
  end
  
  # all downloads and viewings
  map.resources :downloads, :viewings

  # contributions (all types)
  map.resources :contributions do |contribution|
    # download history
    contribution.resources :downloads

    # viewing history
    contribution.resources :viewings
  end

  # all policies for all contributables
  map.resources :policies, :member => { :test => :post } do |policy|
    # policies have nested permissions that name contributors
    policy.resources :permissions
  end

  # message center for current_user (User.find session[:user_id])
  map.resources :messages

  # all ***ship's
  map.resources :relationships, :memberships, :friendships

  # all users
  map.resources :users, :collection => { :search => :get } do |user|
    # friendships 'owned by' user (user --> friendship --> friend)
    user.resources :friendships, :member => { :accept => :get }

    # memberships 'owned by' user (user --> membership --> network)
    user.resources :memberships, :member => { :accept => :get }

    # user profile
    user.resource :profile, :controller => :profiles

    # pictures 'owned by' user
    user.resources :pictures, :member => { :select => :get }
  end

  # all networks
  map.resources :networks, :collection => { :search => :get }, :member => { :membership_create => :get, :membership_request => :get } do |network|
    # relationships 'accepted by' network (relation --> relationship --> network)
    network.resources :relationships, :member => { :accept => :get }
  end

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)
  map.owned_networks 'users/:user_id/networks', :controller => 'networks', :action => 'index'

  # You can have the root of your site routed by hooking up ''
  # -- just remember to delete public/index.html.
#  map.connect '', :controller => 'users'

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
end
