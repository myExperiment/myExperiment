require 'lib/rest'

ActionController::Routing::Routes.draw do |map|

  # rest routes
  rest_routes(map)

  # LoD routes
  if Conf.rdfgen_enable

    map.connect '/:contributable_type/:contributable_id/attributions/:attribution_id.:format',
      :controller => 'linked_data', :action => 'attributions'

    map.connect '/:contributable_type/:contributable_id/citations/:citation_id.:format',
      :controller => 'linked_data', :action => 'citations'

    map.connect '/:contributable_type/:contributable_id/comments/:comment_id.:format',
      :controller => 'linked_data', :action => 'comments'

    map.connect '/:contributable_type/:contributable_id/credits/:credit_id.:format',
      :controller => 'linked_data', :action => 'credits'

    map.connect '/users/:user_id/favourites/:favourite_id.:format',
      :controller => 'linked_data', :action => 'favourites'

    map.connect '/packs/:contributable_id/local_pack_entries/:local_pack_entry_id.:format',
      :controller => 'linked_data', :action => 'local_pack_entries',
      :contributable_type => 'packs'

    map.connect '/packs/:contributable_id/remote_pack_entries/:remote_pack_entry_id.:format',
      :controller => 'linked_data', :action => 'remote_pack_entries',
      :contributable_type => 'packs'

    map.connect '/:contributable_type/:contributable_id/policies/:policy_id.:format',
      :controller => 'linked_data', :action => 'policies'

    map.connect '/:contributable_type/:contributable_id/ratings/:rating_id.:format',
      :controller => 'linked_data', :action => 'ratings'

    map.connect '/tags/:tag_id/taggings/:tagging_id.:format',
      :controller => 'linked_data', :action => 'taggings'
  end

  map.content '/content', :controller => 'content', :action => 'index', :conditions => { :method => :get }
  map.formatted_content '/content.:format', :controller => 'content', :action => 'index', :conditions => { :method => :get }

  # Runners
  map.resources :runners, :member => { :verify => :get }
  
  # Experiments
  map.resources :experiments do |e|
    # Experiments have nested Jobs
    e.resources :jobs, 
      :member => { :save_inputs => :post, 
                   :submit_job => :post, 
                   :refresh_status => :get, 
                   :refresh_outputs => :get, 
                   :outputs_xml => :get, 
                   :outputs_package => :get, 
                   :rerun => :post, 
                   :render_output => :get }
  end
  
  # mashup
  map.resource :mashup
  
  # search
  map.resource :search,
    :member => { :live_search => :get, :open_search_beta => :get }

  # tags
  map.resources :tags

  # sessions and RESTful authentication
  map.resource :session
  
  # openid authentication
  map.resource :openid
  
  # packs
  map.resources :packs, 
    :collection => { :search => :get }, 
    :member => { :statistics => :get,
                 :favourite => :post,
                 :favourite_delete => :delete,
                 :tag => :post,
                 :new_item => :get,
                 :create_item => :post, 
                 :edit_item => :get,
                 :update_item => :put,
                 :destroy_item => :delete,
                 :download => :get,
                 :quick_add => :post,
                 :resolve_link => :post,
                 :items => :get } do |pack|
    pack.resources :comments, :collection => { :timeline => :get }
  end
    

  # workflows (downloadable)
  map.resources :workflows, 
    :collection => { :search => :get }, 
    :member => { :new_version => :get, 
                 :download => :get, 
                 :launch => :get,
                 :statistics => :get,
                 :favourite => :post, 
                 :favourite_delete => :delete, 
                 :rate => :post, 
                 :tag => :post, 
                 :create_version => :post, 
                 :destroy_version => :delete, 
                 :edit_version => :get, 
                 :update_version => :put, 
                 :process_tag_suggestions => :post,
                 :tag_suggestions => :get } do |workflow|
    # workflows have nested citations
    workflow.resources :citations
    workflow.resources :reviews
    workflow.resources :comments, :collection => { :timeline => :get }
  end

  # workflow redirect for linked data model
  map.workflow_version           '/workflows/:id/versions/:version',         :conditions => { :method => :get }, :controller => 'workflows', :action => 'show'
  map.formatted_workflow_version '/workflows/:id/versions/:version.:format', :conditions => { :method => :get }, :controller => 'workflows', :action => 'show'

  # curation
  ['workflows', 'files', 'packs'].each do |contributable_type|
    map.curation "#{contributable_type}/:contributable_id/curation",
      :contributable_type => contributable_type,
      :controller         => 'contributions',
      :action             => 'curation',
      :conditions         => { :method => :get }
  end

  # files (downloadable)
  map.resources :files, 
    :controller => :blobs, 
    :collection => { :search => :get }, 
    :member => { :download => :get,
                 :statistics => :get,
                 :favourite => :post,
                 :favourite_delete => :delete,
                 :rate => :post, 
                 :tag => :post } do |file|
    # Due to restrictions in the version of Rails used (v1.2.3), 
    # we cannot have reviews as nested resources in more than one top level resource.
    # ie: we cannot have polymorphic nested resources.
    #file.resources :reviews
    file.resources :comments, :collection => { :timeline => :get }
  end

  # blogs
  map.resources :blogs do |blog|
    # blogs have nested posts
    blog.resources :blog_posts
  end
  
  # content_types
  map.resources :content_types

  # all downloads and viewings
  map.resources :downloads, :viewings

  # messages
  map.resources :messages, :collection => { :sent => :get, :delete_all_selected => :delete }

  # all ***ship's
  map.resources :memberships, :friendships

  # all oauth
  map.oauth '/oauth',:controller=>'oauth',:action=>'index'
  map.authorize '/oauth/authorize',:controller=>'oauth',:action=>'authorize'
  map.request_token '/oauth/request_token',:controller=>'oauth',:action=>'request_token'
  map.access_token '/oauth/access_token',:controller=>'oauth',:action=>'access_token'
  map.test_request '/oauth/test_request',:controller=>'oauth',:action=>'test_request'

  # User timeline
  map.connect 'users/timeline', :controller => 'users', :action => 'timeline'
  map.connect 'users/users_for_timeline', :controller => 'users', :action => 'users_for_timeline'

  # For email confirmations (user accounts)
  map.connect 'users/confirm_email/:hash', :controller => "users", :action => "confirm_email"
  
  # For password resetting (user accounts)
  map.connect 'users/forgot_password', :controller => "users", :action => "forgot_password"
  map.connect 'users/reset_password/:reset_code', :controller => "users", :action => "reset_password"
  
  [ 'news', 'friends', 'groups', 'workflows', 'files', 'packs', 'forums', 'blogs', 'credits', 'tags', 'favourites' ].each do |tab|
    map.connect "users/:id/#{tab}", :controller => 'users', :action => tab
  end
  
  # all users
  map.resources :users, 
    :collection => { :all => :get, 
                     :search => :get, 
                     :invite => :get } do |user|

    # friendships 'owned by' user (user --> friendship --> friend)
    user.resources :friendships, :member => { :accept => :post }

    # memberships 'owned by' user (user --> membership --> network)
    user.resources :memberships, :member => { :accept => :post }

    # user profile
    user.resource :profile, :controller => :profiles

    # pictures 'owned by' user
    user.resources :pictures, :member => { :select => :get }
    
    # user's history
    user.resource :userhistory, :controller => :userhistory
  end

  map.resources :groups, 
    :controller => :networks, 
    :collection => { :all => :get, :search => :get }, 
    :member => { :invite => :get,
                 :membership_invite => :post,
                 :membership_invite_external => :post,
                 :membership_request => :get, 
                 :rate => :post, 
                 :tag => :post } do |group|
    group.resources :announcements, :controller => :group_announcements
    group.resources :comments, :collection => { :timeline => :get }
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
#  map.connect '', :controller => 'users'

  # Explicit redirections
  map.connect 'exercise', :controller => 'redirects', :action => 'exercise'
  map.connect 'google', :controller => 'redirects', :action => 'google'
  map.connect 'benchmarks', :controller => 'redirects', :action => 'benchmarks'

  # alternate download link to work around lack of browser redirects when downloading
  map.connect ':controller/:id/download/:name', :action => 'named_download', :requirements => { :name => /.*/ }
  
  map.connect 'files/:id/download/:name', :controller => 'blobs', :action => 'named_download', :requirements => { :name => /.*/ }
  
  # (general) announcements
  # NB! this is moved to the bottom of the file for it to be discovered
  # before 'announcements' resource within 'groups'
  map.resources :announcements

  map.resources :licenses
  map.resources :license_attributes

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
end

