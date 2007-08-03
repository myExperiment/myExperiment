ActionController::Routing::Routes.draw do |map|
  # message center for current_user (User.find session[:user_id])
  map.resources :messages

  # all pictures, all profiles
  map.resources :pictures, :profiles
  
  # all ***ship's
  map.resources :relationships, :memberships, :friendships

  # all users
  map.resources :users do |user|
    # friendships 'owned by' user (user --> friendship --> friend)
    user.resources :friendships, :member => { :accept => :get }
    
    # memberships 'owned by' user (user --> membership --> network)
    user.resources :memberships
    
    # user profile
    user.resource :profile, :controller => :profiles
    
    # pictures 'owned by' user
    user.resources :pictures
  end
  
  # all networks
  map.resources :networks do |network|
    # memberships 'accepted by' network (user --> membership --> network)
    network.resources :memberships, :member => { :accept => :get }
    
    # relationships 'accepted by' network (relation --> relationship --> network)
    network.resources :relationships
  end

  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
end
