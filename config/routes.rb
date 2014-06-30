require 'rest'

MyExperiment::Application.routes.draw do
  # REST API routes
  rest_routes

  match '/' => 'home#front_page'
  match '/home' => 'home#index', :as => :home
  match '/content' => 'content#index', :as => :content, :via => :get
  match '/content.:format' => 'content#index', :as => :formatted_content, :via => :get

  # TODO: Remove me
  resources :runners do
    member do
      get :verify
    end
  end

  # TODO: Remove me
  resources :experiments do
    resources :jobs do
      member do
        post :save_inputs
        post :submit_job
        get :refresh_status
        get :refresh_outputs
        get :outputs_xml
        get :outputs_package
        post :rerun
        get :render_output
      end
    end
  end

  resources :ontologies
  resources :predicates
  resource :mashup

  resource :search do
    member do
      get :live_search
      get :open_search_beta
    end
  end

  resources :tags

  resource :session do
    collection do
      post :create
    end
  end

  resource :openid

  resources :packs do
    collection do
      get :search
    end
    member do
      get :statistics
      post :favourite
      delete :favourite_delete
      post :tag
      get :new_item
      post :create_item
      get :edit_item
      put :update_item
      delete :destroy_item
      get :download
      post :quick_add
      post :resolve_link
      post :snapshot
      get :items
    end
    resources :comments do
      collection do
        get :timeline
      end
    end

    resources :relationships do
      collection do
        get :edit_relationships
      end
    end
  end

  resources :workflows do
    collection do
      get :search
    end
    member do
      get :new_version
      get :download
      get :statistics
      post :favourite
      delete :favourite_delete
      post :rate
      post :tag
      post :create_version
      get :edit_version
      put :update_version
      post :process_tag_suggestions
      get :tag_suggestions
      get :component_validity
    end
    resources :citations
    resources :reviews
    resources :previews
    resources :comments do
      collection do
        get :timeline
      end
    end
  end

  # workflow redirect for linked data model
  match '/workflows/:id/versions/:version' => 'workflows#show', :as => :workflow_version, :via => :get
  match '/workflows/:id/versions/:version.:format' => 'workflows#show', :as => :formatted_workflow_version, :via => :get
  # blob redirect for linked data model
  match '/files/:id/versions/:version' => 'blobs#show', :as => :blob_version, :via => :get
  match '/files/:id/versions/:version.:format' => 'blobs#show', :as => :formatted_blob_version, :via => :get
  # pack redirect for linked data model
  match '/packs/:id/versions/:version' => 'packs#show', :as => :pack_version, :via => :get
  match '/packs/:id/versions/:version.:format' => 'packs#show', :as => :formatted_pack_version, :via => :get

  # ???
  match '/files/:id/versions/:version/suggestions' => 'blobs#suggestions', :as => :blob_version_suggestions, :via => :get
  match '/files/:id/versions/:version/process_suggestions' => 'blobs#process_suggestions', :as => :blob_version_process_suggestions, :via => :post

  # versioned preview images
  match '/workflows/:workflow_id/versions/:version/previews/:id' => 'previews#show', :as => :workflow_version_preview, :via => :get
  match '/workflows/:workflow_id/versions/:version/previews/:id.:format' => 'previews#show', :as => :formatted_workflow_version_preview, :via => :get

  # Curation
  match 'workflows/:contributable_id/curation' => 'contributions#curation', :as => :curation, :contributable_type => 'workflows', :via => :get
  match 'files/:contributable_id/curation' => 'contributions#curation', :as => :curation, :contributable_type => 'files', :via => :get
  match 'packs/:contributable_id/curation' => 'contributions#curation', :as => :curation, :contributable_type => 'packs', :via => :get

  # files (downloadable)
  resources :blobs do
    collection do
      get :search
    end
    member do
      get :download
      get :statistics
      post :favourite
      delete :favourite_delete
      post :rate
      get :suggestions
      post :process_suggestions
      post :tag
    end
    resources :comments do
      collection do
        get :timeline
      end
    end
  end

  resources :content_types

  resources :messages do
    collection do
      get :sent
      delete :delete_all_selected
    end
  end

  # Oauth
  match '/oauth/authorize' => 'oauth#authorize', :as => :authorize
  match '/oauth/request_token' => 'oauth#request_token', :as => :request_token
  match '/oauth/access_token' => 'oauth#access_token', :as => :access_token
  match '/oauth/test_request' => 'oauth#test_request', :as => :test_request
  resources :oauth

  # User timeline
  match 'users/timeline' => 'users#timeline'
  match 'users/users_for_timeline' => 'users#users_for_timeline'

  # For email confirmations (user accounts)
  match 'users/confirm_email/:hash' => 'users#confirm_email'
  match 'users/forgot_password' => 'users#forgot_password'

  #  # For password resetting (user accounts)
  match 'users/reset_password/:reset_code' => 'users#reset_password'

  # User tabs
  match 'users/:id/news' => 'users#news'
  match 'users/:id/friends' => 'users#friends'
  match 'users/:id/groups' => 'users#groups'
  match 'users/:id/forums' => 'users#forums'
  match 'users/:id/credits' => 'users#credits'
  match 'users/:id/tags' => 'users#tags'
  match 'users/:id/favourites' => 'users#favourites'
  # Users
  resources :users do
    collection do
      get :all
      get :check
      post :change_status
      get :search
      get :invite
    end

    resources :friendships do
      member do
        post :accept
      end
    end

    resources :memberships do
      member do
        post :accept
      end
    end

    resource :profile
    resources :pictures do
      member do
        get :select
      end
    end

    resource :userhistory
    resources :reports
    resources :workflows, :only => :index
    resources :blobs, :only => :index
    resources :packs, :only => :index
  end

  # Groups
  resources :networks do
    collection do
      get :all
      get :search
    end

    member do
      get :content
      get :invite
      post :membership_invite
      post :membership_invite_external
      get :membership_request
      post :rate
      post :sync_feed
      put :subscription
      delete :subscription
      post :tag
    end

    resources :group_announcements

    resources :comments do
      collection do
        get :timeline
      end
    end

    resources :policies

    resources :activities do
      member do
        put :feature
        delete :feature
      end
      resources :comments
    end

    resources :workflows, :only => :index
    resources :blobs, :only => :index
    resources :packs, :only => :index
  end

  # Explicit redirections
  match 'google' => 'redirects#google'
  match 'benchmarks' => 'redirects#benchmarks'

  # alternate download link to work around lack of browser redirects when downloading
  match ':controller/:id/download/:name' => '#named_download', :constraints => { :name => /.*/ }
  match 'files/:id/download/:name' => 'blobs#named_download', :constraints => { :name => /.*/ }
  match 'files/:id/versions/:version/download/:name' => 'blobs#named_download_with_version', :constraints => { :name => /.*/ }

  # Topics
  match 'topics/tag_feedback' => 'topics#tag_feedback'
  match 'topics/topic_feedback' => 'topics#topic_feedback'
  resources :topics

  resources :announcements

  resources :licenses

  resources :license_attributes

  resources :policies, :only => :show

  # Generate special alias routes for external sites point to
  Conf.external_site_integrations.each_value do |data|
    match data["path"] => "#{data["redirect"]["controller"]}\##{data["redirect"]["action"]}", :filter => data["redirect"]["filter"]
  end
  match 'clear_external_site_session_info' => 'application#clear_external_site_session_info'

  # LoD routes
  if Conf.rdfgen_enable
    match '/:contributable_type/:contributable_id/attributions/:attribution_id.:format' => 'linked_data#attributions', :via => :get
    match '/:contributable_type/:contributable_id/citations/:citation_id.:format' => 'linked_data#citations', :via => :get
    match '/:contributable_type/:contributable_id/comments/:comment_id.:format' => 'linked_data#comments', :via => :get
    match '/:contributable_type/:contributable_id/credits/:credit_id.:format' => 'linked_data#credits', :via => :get
    match '/users/:user_id/favourites/:favourite_id.:format' => 'linked_data#favourites', :via => :get
    match '/packs/:contributable_id/local_pack_entries/:local_pack_entry_id.:format' => 'linked_data#local_pack_entries', :contributable_type => 'packs', :via => :get
    match '/packs/:contributable_id/remote_pack_entries/:remote_pack_entry_id.:format' => 'linked_data#remote_pack_entries', :contributable_type => 'packs', :via => :get
    match '/:contributable_type/:contributable_id/policies/:policy_id.:format' => 'linked_data#policies', :via => :get
    match '/:contributable_type/:contributable_id/ratings/:rating_id.:format' => 'linked_data#ratings', :via => :get
    match '/tags/:tag_id/taggings/:tagging_id.:format' => 'linked_data#taggings', :via => :get
  end

  # RODL routes.  There are no HTML pages for 'new' and 'edit' so the routes
  # are generated without the resource helpers.
  match '/rodl/ROs' => 'research_objects#index', :as => :research_objects, :via => :get
  match '/rodl/ROs' => 'research_objects#create', :via => :post
  match '/rodl/zippedROs/:id' => 'research_objects#download_zip', :as => :zipped_research_object, :via => :get
  match '/rodl/ROs/:id' => 'research_objects#show', :as => :research_object, :via => :get
  match '/rodl/ROs/:research_object_id' => 'resources#post', :via => :post
  match '/rodl/ROs/:id' => 'research_objects#update', :via => :put
  match '/rodl/ROs/:id' => 'research_objects#destroy', :via => :delete
  match 'research_object_resource' => 'resources#show', :as => :named_route, :constraints => { :id => /.*/ }, :via => :get
  match '/rodl/ROs/:research_object_id/:id' => 'resources#update', :constraints => { :id => /.*/ }, :via => :put
  match '/rodl/ROs/:research_object_id/:id' => 'resources#delete', :constraints => { :id => /.*/ }, :via => :delete
  match '/rodl/ROs/:research_object_id/:path' => 'resources#post', :constraints => { :path => /.*/ }, :via => :post

  # TODO: Remove me
  match '/:controller(/:action(/:id))'
end
