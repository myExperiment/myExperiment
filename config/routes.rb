ActionController::Routing::Routes.draw do |map|
  # forums
  map.from_plugin :savage_beast
  
  # announcements
  map.resources :announcements
  
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

  # For email confirmations (user accounts)
  map.connect 'users/confirm_email/:hash', :controller => "users", :action => "confirm_email"
  
  # For password resetting (user accounts)
  map.connect 'users/forgot_password', :controller => "users", :action => "forgot_password"
  map.connect 'users/reset_password/:reset_code', :controller => "users", :action => "reset_password"

  # all blobs (aka files)
  map.connect 'files/all', :controller => 'blobs', :action => 'all'

  # all users
  map.connect 'users/all', :controller => 'users', :action => 'all'

  # all networks (aka groups)
  map.connect 'groups/all', :controller => 'networks', :action => 'all'

  # all workflows
  map.connect 'workflows/all', :controller => 'workflows', :action => 'all'

  # workflows (downloadable)
  map.resources :workflows, :collection => { :search => :get }, :member => { :new_version => :get, :download => :get, :bookmark => :post, :comment => :post, :comment_delete => :delete, :rate => :post, :tag => :post, :create_version => :post, :destroy_version => :delete, :edit_version => :get, :update_version => :put } do |workflow|
    # workflows have nested citations
    workflow.resources :citations
    workflow.resources :reviews
  end

  # files (downloadable)
  map.resources :files, :controller => :blobs, :collection => { :search => :get }, :member => { :download => :get, :comment => :post, :comment_delete => :delete, :rate => :post, :tag => :post } do |file|
    # Due to restrictions in the version of Rails used (v1.2.3), 
    # we cannot have reviews as nested resources in more than one top level resource.
    # ie: we cannot have polymorphic nested resources.
    #file.resources :reviews
  end

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
    
    # user's history
    user.resource :userhistory, :controller => :userhistory
  end

  map.resources :groups, :controller => :networks, :collection => { :search => :get }, :member => { :membership_invite => :get, :membership_request => :get, :comment => :post, :comment_delete => :delete, :rate => :post, :tag => :post } do |group|
    # relationships 'accepted by' group (relation --> relationship --> group)
    group.resources :relationships, :member => { :accept => :get }
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
  
  # Sitealizer
  map.connect '/sitealizer/:action', :controller => 'sitealizer'

  # Explicit redirections
  map.connect 'exercise', :controller => 'redirects', :action => 'exercise'
  map.connect 'google', :controller => 'redirects', :action => 'google'

  # alternate download link to work around lack of browser redirects when downloading
  map.connect ':controller/:id/download/:name', :action => 'named_download', :requirements => { :name => /.*/ }
  
  # simple_pages plugin
  map.from_plugin :simple_pages

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
end
