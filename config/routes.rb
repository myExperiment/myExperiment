require 'rest'

ActionController::Routing::Routes.draw do |map|

  # rest routes
  rest_routes(map)

  map.home '/home', :controller => 'home', :action => 'index'

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

  # Ontologies
  map.resources :ontologies

  # Predicates
  map.resources :predicates

  # mashup
  map.resource :mashup, :controller => 'mashup'
  
  # search
  map.resource :search,
    :controller => 'search',
    :member => { :live_search => :get, :open_search_beta => :get }

  # tags
  map.resources :tags

  # sessions and RESTful authentication
  map.resource :session, :collection => { :create => :post }
  
  # openid authentication
  map.resource :openid, :controller => 'openid'
  
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
                 :snapshot => :post,
                 :items => :get } do |pack|
    pack.resources :comments, :collection => { :timeline => :get }
    pack.resources :relationships, :collection => { :edit_relationships => :get }
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
                 :edit_version => :get,
                 :update_version => :put, 
                 :process_tag_suggestions => :post,
                 :tag_suggestions => :get } do |workflow|
    # workflows have nested citations
    workflow.resources :citations
    workflow.resources :reviews
    workflow.resources :previews
    workflow.resources :comments, :collection => { :timeline => :get }
  end

  # workflow redirect for linked data model
  map.workflow_version           '/workflows/:id/versions/:version',         :conditions => { :method => :get }, :controller => 'workflows', :action => 'show'
  map.formatted_workflow_version '/workflows/:id/versions/:version.:format', :conditions => { :method => :get }, :controller => 'workflows', :action => 'show'

  # blob redirect for linked data model
  map.blob_version           '/files/:id/versions/:version',         :conditions => { :method => :get }, :controller => 'blobs', :action => 'show'
  map.formatted_blob_version '/files/:id/versions/:version.:format', :conditions => { :method => :get }, :controller => 'blobs', :action => 'show'

  # pack redirect for linked data model
  map.pack_version           '/packs/:id/versions/:version',         :conditions => { :method => :get }, :controller => 'packs', :action => 'show'
  map.formatted_pack_version '/packs/:id/versions/:version.:format', :conditions => { :method => :get }, :controller => 'packs', :action => 'show'

  map.blob_version_suggestions '/files/:id/versions/:version/suggestions', :conditions => { :method => :get }, :controller => 'blobs', :action => 'suggestions'
  map.blob_version_process_suggestions '/files/:id/versions/:version/process_suggestions', :conditions => { :method => :post }, :controller => 'blobs', :action => 'process_suggestions'

  # versioned preview images
  ['workflow'].each do |x|

    eval("map.#{x}_version_preview '/#{x.pluralize}/:#{x}_id/versions/:version/previews/:id'," +
        " :conditions => { :method => :get}, :controller => 'previews', :action => 'show'")

    eval("map.formatted_#{x}_version_preview '/#{x.pluralize}/:#{x}_id/versions/:version/previews/:id.:format'," +
        " :conditions => { :method => :get}, :controller => 'previews', :action => 'show'")
  end

  map.galaxy_tool 'workflows/:id/versions/:version/galaxy_tool', :controller => 'workflows', :action => 'galaxy_tool'
  map.galaxy_tool_download 'workflows/:id/versions/:version/galaxy_tool_download', :controller => 'workflows', :action => 'galaxy_tool_download'

  # curation
  ['workflows', 'files', 'packs'].each do |contributable_type|
    map.curation "#{contributable_type}/:contributable_id/curation",
      :contributable_type => contributable_type,
      :controller         => 'contributions',
      :action             => 'curation',
      :conditions         => { :method => :get }
  end

  # files (downloadable)
  map.resources :blobs,
    :as => :files,
    :collection => { :search => :get }, 
    :member => { :download => :get,
                 :statistics => :get,
                 :favourite => :post,
                 :favourite_delete => :delete,
                 :rate => :post, 
                 :suggestions => :get,
                 :process_suggestions => :post,
                 :tag => :post } do |blob|
    # Due to restrictions in the version of Rails used (v1.2.3), 
    # we cannot have reviews as nested resources in more than one top level resource.
    # ie: we cannot have polymorphic nested resources.
    #blob.resources :reviews
    blob.resources :comments, :collection => { :timeline => :get }
  end

  # content_types
  map.resources :content_types

  # messages
  map.resources :messages, :collection => { :sent => :get, :delete_all_selected => :delete }

  # all oauth
  map.authorize '/oauth/authorize',:controller=>'oauth',:action=>'authorize'
  map.request_token '/oauth/request_token',:controller=>'oauth',:action=>'request_token'
  map.access_token '/oauth/access_token',:controller=>'oauth',:action=>'access_token'
  map.test_request '/oauth/test_request',:controller=>'oauth',:action=>'test_request'
  map.resources :oauth

  # User timeline
  map.connect 'users/timeline', :controller => 'users', :action => 'timeline'
  map.connect 'users/users_for_timeline', :controller => 'users', :action => 'users_for_timeline'

  # For email confirmations (user accounts)
  map.connect 'users/confirm_email/:hash', :controller => "users", :action => "confirm_email"
  
  # For password resetting (user accounts)
  map.connect 'users/forgot_password', :controller => "users", :action => "forgot_password"
  map.connect 'users/reset_password/:reset_code', :controller => "users", :action => "reset_password"
  
  [ 'news', 'friends', 'groups', 'forums', 'credits', 'tags', 'favourites' ].each do |tab|
    map.connect "users/:id/#{tab}", :controller => 'users', :action => tab
  end
  
  # all users
  map.resources :users, 
    :collection => { :all => :get, 
                     :check => :get,
                     :change_status => :post,
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

    # user's reports of inappropriate content
    user.resources :reports, :controller => :user_reports

    # user's uploaded resources
    user.resources :workflows, :only => :index
    user.resources :blobs, :only => :index, :as => :files
    user.resources :packs, :only => :index
  end

  map.resources :networks,
    :as => :groups,
    :collection => { :all => :get, :search => :get }, 
    :member => { :content => :get,
                 :invite => :get,
                 :membership_invite => :post,
                 :membership_invite_external => :post,
                 :membership_request => :get, 
                 :rate => :post, 
                 :sync_feed => :post,
                 :subscription => [:put, :delete],
                 :tag => :post } do |network|
    network.resources :group_announcements, :as => :announcements, :name_prefix => nil
    network.resources :comments, :collection => { :timeline => :get }
    network.resources :policies, :controller => 'group_policies'
    network.resources :activities, :member => { :feature => [:put, :delete] } do |activity|
      activity.resources :comments
    end

    # resources shared with network
    network.resources :workflows, :only => :index
    network.resources :blobs, :only => :index, :as => :files
    network.resources :packs, :only => :index
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
  map.connect 'google', :controller => 'redirects', :action => 'google'
  map.connect 'benchmarks', :controller => 'redirects', :action => 'benchmarks'

  # alternate download link to work around lack of browser redirects when downloading
  map.connect ':controller/:id/download/:name', :action => 'named_download', :requirements => { :name => /.*/ }
  
  map.connect 'files/:id/download/:name', :controller => 'blobs', :action => 'named_download', :requirements => { :name => /.*/ }
  map.connect 'files/:id/versions/:version/download/:name', :controller => 'blobs', :action => 'named_download_with_version', :requirements => { :name => /.*/ }

  # map.connect 'topics', :controller => 'topics', :action => 'index'
  map.connect 'topics/tag_feedback', :controller => 'topics', :action => 'tag_feedback'
  map.connect 'topics/topic_feedback', :controller => 'topics', :action => 'topic_feedback'
  map.resources :topics

  # map.connect 'topics/:id', :controller => 'topics', :action => 'show'
  # (general) announcements
  # NB! this is moved to the bottom of the file for it to be discovered
  # before 'announcements' resource within 'groups'
  map.resources :announcements

  map.resources :licenses
  map.resources :license_attributes

  map.resources :policies, :only => :show

  # Generate special alias routes for external sites point to
  Conf.external_site_integrations.each_value do |data|
    map.connect data["path"], data["redirect"].symbolize_keys #Convert string keys to symbols
  end

  map.connect 'clear_external_site_session_info', :controller => 'application', :action => 'clear_external_site_session_info'

  # LoD routes
  if Conf.rdfgen_enable

    map.connect '/:contributable_type/:contributable_id/attributions/:attribution_id.:format',
      :controller => 'linked_data', :action => 'attributions', :conditions => { :method => :get }

    map.connect '/:contributable_type/:contributable_id/citations/:citation_id.:format',
      :controller => 'linked_data', :action => 'citations', :conditions => { :method => :get }

    map.connect '/:contributable_type/:contributable_id/comments/:comment_id.:format',
      :controller => 'linked_data', :action => 'comments', :conditions => { :method => :get }

    map.connect '/:contributable_type/:contributable_id/credits/:credit_id.:format',
      :controller => 'linked_data', :action => 'credits', :conditions => { :method => :get }

    map.connect '/users/:user_id/favourites/:favourite_id.:format',
      :controller => 'linked_data', :action => 'favourites', :conditions => { :method => :get }

    map.connect '/packs/:contributable_id/local_pack_entries/:local_pack_entry_id.:format',
      :controller => 'linked_data', :action => 'local_pack_entries',
      :contributable_type => 'packs', :conditions => { :method => :get }

    map.connect '/packs/:contributable_id/remote_pack_entries/:remote_pack_entry_id.:format',
      :controller => 'linked_data', :action => 'remote_pack_entries',
      :contributable_type => 'packs', :conditions => { :method => :get }

    map.connect '/:contributable_type/:contributable_id/policies/:policy_id.:format',
      :controller => 'linked_data', :action => 'policies', :conditions => { :method => :get }

    map.connect '/:contributable_type/:contributable_id/ratings/:rating_id.:format',
      :controller => 'linked_data', :action => 'ratings', :conditions => { :method => :get }

    map.connect '/tags/:tag_id/taggings/:tagging_id.:format',
      :controller => 'linked_data', :action => 'taggings', :conditions => { :method => :get }
  end

  # RODL routes.  There are no HTML pages for 'new' and 'edit' so the routes
  # are generated without the resource helpers.

  map.research_objects "/rodl/ROs", :controller => "research_objects", :action => "index",  :conditions => { :method => :get }
  map.connect          "/rodl/ROs", :controller => "research_objects", :action => "create", :conditions => { :method => :post }

  map.zipped_research_object "/rodl/zippedROs/:id", :controller => "research_objects", :action => "download_zip", :conditions => { :method => :get }

  map.research_object "/rodl/ROs/:id", :controller => "research_objects", :action => "show",           :conditions => { :method => :get }
  map.connect         "/rodl/ROs/:research_object_id", :controller => "resources",        :action => "post", :conditions => { :method => :post }
  map.connect         "/rodl/ROs/:id", :controller => "research_objects", :action => "update",         :conditions => { :method => :put }
  map.connect         "/rodl/ROs/:id", :controller => "research_objects", :action => "destroy",        :conditions => { :method => :delete }

  map.named_route "research_object_resource", "/rodl/ROs/:research_object_id/:id",
    :controller   => "resources",
    :action       => "show",
    :conditions   => { :method => :get },
    :requirements => { :id => /.*/ }

  map.connect "/rodl/ROs/:research_object_id/:id",
    :controller   => "resources",
    :action       => "update",
    :conditions   => { :method => :put },
    :requirements => { :id => /.*/ }

  map.connect "/rodl/ROs/:research_object_id/:id",
    :controller   => "resources",
    :action       => "delete",
    :conditions   => { :method => :delete },
    :requirements => { :id => /.*/ }

  map.connect "/rodl/ROs/:research_object_id/:path",
    :controller   => "resources",
    :action       => "post",
    :conditions   => { :method => :post },
    :requirements => { :path => /.*/ }

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
end

