ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action
  # Sample of named route:
  #map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)
  
  map.from_plugin :savage_beast

  # You can have the root of your site routed by hooking up ''
  # -- just remember to delete public/index.html.
  map.connect '', :controller => "my"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  map.connect 'projects/', :controller => 'projects', :action => 'list'
  map.connect 'projects/:id', :controller => 'projects', :action => 'show'
  map.connect 'projects/:id/:page', :controller => 'pages', :action => 'show'
  map.connect 'admin/projects/:action/:id', :controller => 'projects'

  map.pages 'pages/:id/:page', :controller => 'pages', :action => 'show'
  map.pages 'pages/update/:id/:name', :controller => 'pages', :action => 'update'
  map.pages 'pages/edit/:id/:page', :controller => 'pages', :action => 'edit'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'


  map.pictures 'pictures/show/:id/:size/image.jpg',
                    :controller => 'pictures',
                    :action => 'show'
                    
  map.user 'profile/show/:id', :controller => 'profile', :action => 'show'
end
