# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 97) do

  create_table "activity_limits", :force => true do |t|
    t.string   "contributor_type", :null => false
    t.integer  "contributor_id",   :null => false
    t.string   "limit_feature",    :null => false
    t.integer  "limit_max"
    t.integer  "limit_frequency"
    t.integer  "current_count",    :null => false
    t.datetime "reset_after"
    t.datetime "promote_after"
  end

  create_table "announcements", :force => true do |t|
    t.string   "title"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "body"
    t.text     "body_html"
  end

  create_table "attributions", :force => true do |t|
    t.integer  "attributor_id"
    t.string   "attributor_type"
    t.integer  "attributable_id"
    t.string   "attributable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "auto_tables", :force => true do |t|
    t.string "name"
    t.text   "schema"
  end

  create_table "blob_versions", :force => true do |t|
    t.integer  "blob_id"
    t.integer  "version"
    t.text     "revision_comments"
    t.string   "title"
    t.text     "body"
    t.text     "body_html"
    t.integer  "content_type_id"
    t.integer  "content_blob_id"
    t.string   "local_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "blobs", :force => true do |t|
    t.integer  "contributor_id"
    t.string   "contributor_type"
    t.string   "local_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title"
    t.text     "body"
    t.text     "body_html"
    t.integer  "content_blob_id"
    t.integer  "content_type_id"
    t.integer  "license_id"
    t.integer  "current_version"
  end

  create_table "blog_posts", :force => true do |t|
    t.integer  "blog_id"
    t.string   "title"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "body_html"
  end

  create_table "blogs", :force => true do |t|
    t.integer  "contributor_id"
    t.string   "contributor_type"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bookmarks", :force => true do |t|
    t.string   "title",             :limit => 50, :default => ""
    t.datetime "created_at",                                      :null => false
    t.string   "bookmarkable_type", :limit => 15, :default => "", :null => false
    t.integer  "bookmarkable_id",                 :default => 0,  :null => false
    t.integer  "user_id",                         :default => 0,  :null => false
  end

  add_index "bookmarks", ["user_id"], :name => "index_bookmarks_on_user_id"

  create_table "citations", :force => true do |t|
    t.integer  "user_id"
    t.integer  "workflow_id"
    t.integer  "workflow_version"
    t.text     "authors"
    t.string   "title"
    t.string   "publication"
    t.datetime "published_at"
    t.datetime "accessed_at"
    t.string   "url"
    t.string   "isbn"
    t.string   "issn"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "client_applications", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.string   "support_url"
    t.string   "callback_url"
    t.string   "key",          :limit => 50
    t.string   "secret",       :limit => 50
    t.integer  "user_id"
    t.string   "key_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "creator_id"
  end

  add_index "client_applications", ["key"], :name => "index_client_applications_on_key", :unique => true

  create_table "comments", :force => true do |t|
    t.text     "comment"
    t.datetime "created_at",                                     :null => false
    t.integer  "commentable_id",                 :default => 0,  :null => false
    t.string   "commentable_type", :limit => 15, :default => "", :null => false
    t.integer  "user_id",                        :default => 0,  :null => false
  end

  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

  create_table "concept_relations", :force => true do |t|
    t.integer "subject_concept_id"
    t.string  "relation_type"
    t.integer "object_concept_id"
  end

  create_table "concepts", :force => true do |t|
    t.datetime "updated_at"
    t.text     "description_html"
    t.string   "phrase"
    t.text     "description"
    t.integer  "vocabulary_id"
    t.datetime "created_at"
  end

  create_table "content_blobs", :force => true do |t|
    t.binary "data", :limit => 2147483647
    t.string "md5",  :limit => 32
    t.string "sha1", :limit => 40
  end

  add_index "content_blobs", ["md5"], :name => "index_content_blobs_on_md5"
  add_index "content_blobs", ["sha1"], :name => "index_content_blobs_on_sha1"

  create_table "content_types", :force => true do |t|
    t.integer  "user_id"
    t.string   "title"
    t.text     "description"
    t.text     "description_html"
    t.string   "mime_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "category"
  end

  create_table "contributions", :force => true do |t|
    t.integer  "contributor_id"
    t.string   "contributor_type"
    t.integer  "contributable_id"
    t.string   "contributable_type"
    t.integer  "policy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "downloads_count",      :default => 0
    t.integer  "viewings_count",       :default => 0
    t.float    "rating"
    t.float    "rank"
    t.integer  "content_type_id"
    t.integer  "license_id"
    t.integer  "site_downloads_count", :default => 0
    t.integer  "site_viewings_count",  :default => 0
    t.string   "label"
    t.string   "layout"
  end

  add_index "contributions", ["contributable_id", "contributable_type"], :name => "index_contributions_on_contributable_id_and_contributable_type"
  add_index "contributions", ["contributor_id", "contributor_type"], :name => "index_contributions_on_contributor_id_and_contributor_type"

  create_table "creditations", :force => true do |t|
    t.integer  "creditor_id"
    t.string   "creditor_type"
    t.integer  "creditable_id"
    t.string   "creditable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "curation_events", :force => true do |t|
    t.integer  "user_id"
    t.string   "category"
    t.string   "object_type"
    t.integer  "object_id"
    t.text     "details"
    t.text     "details_html"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "downloads", :force => true do |t|
    t.integer  "contribution_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.string   "user_agent"
    t.boolean  "accessed_from_site", :default => false
    t.string   "kind"
  end

  add_index "downloads", ["contribution_id"], :name => "index_downloads_on_contribution_id"

  create_table "experiments", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.text     "description_html"
    t.integer  "contributor_id"
    t.string   "contributor_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "federation_sources", :force => true do |t|
    t.string "name"
  end

  create_table "friendships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "friend_id"
    t.datetime "created_at"
    t.datetime "accepted_at"
    t.string   "message",     :limit => 500
  end

  add_index "friendships", ["friend_id"], :name => "index_friendships_on_friend_id"
  add_index "friendships", ["user_id"], :name => "index_friendships_on_user_id"

  create_table "group_announcements", :force => true do |t|
    t.string   "title"
    t.integer  "network_id"
    t.integer  "user_id"
    t.boolean  "public",     :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "body"
    t.text     "body_html"
  end

  create_table "jobs", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.text     "description_html"
    t.integer  "experiment_id"
    t.integer  "user_id"
    t.integer  "runnable_id"
    t.integer  "runnable_version"
    t.string   "runnable_type"
    t.integer  "runner_id"
    t.string   "runner_type"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.string   "last_status"
    t.datetime "last_status_at"
    t.string   "job_uri"
    t.binary   "job_manifest",     :limit => 2147483647
    t.string   "inputs_uri"
    t.binary   "inputs_data",      :limit => 2147483647
    t.string   "outputs_uri"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_job_id"
  end

  create_table "key_permissions", :force => true do |t|
    t.integer "client_application_id"
    t.string  "for"
  end

  create_table "labels", :force => true do |t|
    t.integer "concept_id"
    t.string  "language"
    t.string  "text"
    t.integer "vocabulary_id"
    t.string  "label_type"
  end

  create_table "license_attributes", :force => true do |t|
    t.integer  "license_id"
    t.integer  "license_option_id"
    t.datetime "created_at"
  end

  create_table "license_options", :force => true do |t|
    t.integer  "user_id"
    t.string   "title"
    t.text     "description"
    t.text     "description_html"
    t.string   "uri"
    t.string   "predicate"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "licenses", :force => true do |t|
    t.integer  "user_id"
    t.string   "unique_name"
    t.string   "title"
    t.text     "description"
    t.text     "description_html"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "memberships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "network_id"
    t.datetime "created_at"
    t.datetime "user_established_at"
    t.datetime "network_established_at"
    t.string   "message",                :limit => 500
    t.boolean  "administrator",                         :default => false
  end

  add_index "memberships", ["network_id"], :name => "index_memberships_on_network_id"
  add_index "memberships", ["user_id"], :name => "index_memberships_on_user_id"

  create_table "messages", :force => true do |t|
    t.integer  "from"
    t.integer  "to"
    t.string   "subject"
    t.text     "body"
    t.integer  "reply_id"
    t.datetime "created_at"
    t.datetime "read_at"
    t.text     "body_html"
    t.boolean  "deleted_by_sender",    :default => false
    t.boolean  "deleted_by_recipient", :default => false
  end

  create_table "networks", :force => true do |t|
    t.integer  "user_id"
    t.string   "title"
    t.string   "unique_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.text     "description_html"
    t.string   "new_member_policy", :default => "open"
    t.integer  "inviter_id"
  end

  add_index "networks", ["user_id"], :name => "index_networks_on_user_id"

  create_table "oauth_nonces", :force => true do |t|
    t.string   "nonce"
    t.integer  "timestamp"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_nonces", ["nonce", "timestamp"], :name => "index_oauth_nonces_on_nonce_and_timestamp", :unique => true

  create_table "oauth_tokens", :force => true do |t|
    t.integer  "user_id"
    t.string   "type",                  :limit => 20
    t.integer  "client_application_id"
    t.string   "token",                 :limit => 50
    t.string   "secret",                :limit => 50
    t.datetime "authorized_at"
    t.datetime "invalidated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_tokens", ["token"], :name => "index_oauth_tokens_on_token", :unique => true

  create_table "ontologies", :force => true do |t|
    t.string   "prefix"
    t.datetime "updated_at"
    t.string   "uri"
    t.string   "title"
    t.text     "description_html"
    t.text     "description"
    t.integer  "user_id"
    t.datetime "created_at"
  end

  create_table "pack_contributable_entries", :force => true do |t|
    t.integer  "pack_id",               :null => false
    t.integer  "contributable_id",      :null => false
    t.integer  "contributable_version"
    t.string   "contributable_type"
    t.text     "comment"
    t.integer  "user_id",               :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pack_remote_entries", :force => true do |t|
    t.integer  "pack_id",       :null => false
    t.string   "title"
    t.string   "uri"
    t.string   "alternate_uri"
    t.text     "comment"
    t.integer  "user_id",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "packs", :force => true do |t|
    t.integer  "contributor_id"
    t.string   "contributor_type"
    t.string   "title"
    t.text     "description"
    t.text     "description_html"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pending_invitations", :force => true do |t|
    t.string   "email"
    t.datetime "created_at"
    t.string   "request_type"
    t.integer  "requested_by"
    t.integer  "request_for"
    t.string   "message",      :limit => 500
    t.string   "token"
  end

  create_table "permissions", :force => true do |t|
    t.integer  "contributor_id"
    t.string   "contributor_type"
    t.integer  "policy_id"
    t.boolean  "download",         :default => false
    t.boolean  "edit",             :default => false
    t.boolean  "view",             :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "permissions", ["policy_id"], :name => "index_permissions_on_policy_id"

  create_table "picture_selections", :force => true do |t|
    t.integer  "user_id"
    t.integer  "picture_id"
    t.datetime "created_at"
  end

  create_table "pictures", :force => true do |t|
    t.binary  "data",    :limit => 16777215
    t.integer "user_id"
  end

  create_table "plugin_schema_info", :id => false, :force => true do |t|
    t.string  "plugin_name"
    t.integer "version"
  end

  create_table "policies", :force => true do |t|
    t.integer  "contributor_id"
    t.string   "contributor_type"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "share_mode"
    t.integer  "update_mode"
    t.boolean  "public_download",  :default => false
    t.boolean  "public_view",      :default => false
  end

  create_table "predicates", :force => true do |t|
    t.datetime "updated_at"
    t.string   "title"
    t.text     "description_html"
    t.string   "phrase"
    t.integer  "ontology_id"
    t.text     "description"
    t.text     "equivalent_to"
    t.datetime "created_at"
  end

  create_table "previews", :force => true do |t|
    t.integer  "svg_blob_id"
    t.integer  "image_blob_id"
    t.datetime "created_at"
  end

  create_table "profiles", :force => true do |t|
    t.integer  "user_id"
    t.integer  "picture_id"
    t.string   "email"
    t.string   "website"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "body"
    t.text     "body_html"
    t.string   "field_or_industry"
    t.string   "occupation_or_roles"
    t.text     "organisations"
    t.string   "location_city"
    t.string   "location_country"
    t.text     "interests"
    t.text     "contact_details"
  end

  add_index "profiles", ["user_id"], :name => "index_profiles_on_user_id"

  create_table "ratings", :force => true do |t|
    t.integer  "rating",                      :default => 0
    t.datetime "created_at",                                  :null => false
    t.string   "rateable_type", :limit => 15, :default => "", :null => false
    t.integer  "rateable_id",                 :default => 0,  :null => false
    t.integer  "user_id",                     :default => 0,  :null => false
  end

  add_index "ratings", ["user_id"], :name => "index_ratings_on_user_id"

  create_table "relationships", :force => true do |t|
    t.string   "objekt_type"
    t.integer  "objekt_id"
    t.string   "subject_type"
    t.integer  "subject_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.integer  "context_id"
    t.integer  "predicate_id"
    t.string   "context_type"
  end

  create_table "remote_workflows", :force => true do |t|
    t.integer "workflow_id"
    t.integer "workflow_version"
    t.integer "taverna_enactor_id"
    t.string  "workflow_uri"
  end

  create_table "reviews", :force => true do |t|
    t.string   "title",                         :default => ""
    t.text     "review"
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.integer  "reviewable_id",                 :default => 0,  :null => false
    t.string   "reviewable_type", :limit => 15, :default => "", :null => false
    t.integer  "user_id",                       :default => 0,  :null => false
  end

  add_index "reviews", ["user_id"], :name => "index_reviews_on_user_id"

  create_table "service_categories", :force => true do |t|
    t.string   "uri"
    t.datetime "updated_at"
    t.integer  "service_id"
    t.string   "label"
    t.datetime "retrieved_at"
    t.datetime "created_at"
  end

  create_table "service_deployments", :force => true do |t|
    t.string   "iso3166_country_code"
    t.string   "city"
    t.string   "submitter_label"
    t.string   "uri"
    t.datetime "updated_at"
    t.string   "submitter_uri"
    t.string   "country"
    t.integer  "service_id"
    t.datetime "created"
    t.integer  "service_provider_id"
    t.string   "flag_url"
    t.string   "endpoint"
    t.datetime "retrieved_at"
    t.datetime "created_at"
  end

  create_table "service_providers", :force => true do |t|
    t.string   "name"
    t.string   "uri"
    t.datetime "updated_at"
    t.text     "description"
    t.datetime "created"
    t.datetime "retrieved_at"
    t.datetime "created_at"
  end

  create_table "service_tags", :force => true do |t|
    t.string   "uri"
    t.datetime "updated_at"
    t.integer  "service_id"
    t.string   "label"
    t.datetime "retrieved_at"
    t.datetime "created_at"
  end

  create_table "service_types", :force => true do |t|
    t.datetime "updated_at"
    t.integer  "service_id"
    t.string   "label"
    t.datetime "retrieved_at"
    t.datetime "created_at"
  end

  create_table "services", :force => true do |t|
    t.string   "documentation_uri"
    t.string   "iso3166_country_code"
    t.string   "city"
    t.string   "name"
    t.string   "provider_uri"
    t.string   "submitter_label"
    t.string   "uri"
    t.datetime "updated_at"
    t.string   "monitor_symbol_url"
    t.datetime "monitor_last_checked"
    t.string   "monitor_label"
    t.string   "country"
    t.string   "submitter_uri"
    t.string   "monitor_small_symbol_url"
    t.text     "monitor_message"
    t.text     "description"
    t.string   "wsdl"
    t.datetime "created"
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.string   "flag_url"
    t.string   "endpoint"
    t.string   "provider_label"
    t.datetime "retrieved_at"
    t.datetime "created_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "user_id"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id", "taggable_type"], :name => "index_taggings_on_tag_id_and_taggable_type"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"
  add_index "taggings", ["user_id", "tag_id", "taggable_type"], :name => "index_taggings_on_user_id_and_tag_id_and_taggable_type"
  add_index "taggings", ["user_id", "taggable_id", "taggable_type"], :name => "index_taggings_on_user_id_and_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string   "name"
    t.integer  "taggings_count",   :default => 0, :null => false
    t.integer  "vocabulary_id"
    t.text     "description"
    t.text     "description_html"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tags", ["name"], :name => "index_tags_on_name"
  add_index "tags", ["taggings_count"], :name => "index_tags_on_taggings_count"

  create_table "taverna_enactors", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "contributor_id"
    t.string   "contributor_type"
    t.string   "url"
    t.string   "username"
    t.string   "crypted_password"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "topic_feedbacks", :force => true do |t|
    t.integer  "score"
    t.integer  "topic_id"
    t.datetime "submit_dt"
    t.integer  "user_id"
  end

  create_table "topic_runs", :force => true do |t|
    t.datetime "runtime"
    t.string   "description"
  end

  create_table "topic_tag_map", :force => true do |t|
    t.integer "topic_id"
    t.boolean "display_flag"
    t.integer "tag_id"
    t.float   "probability"
  end

  create_table "topic_workflow_map", :force => true do |t|
    t.integer "topic_id"
    t.boolean "display_flag"
    t.integer "workflow_id"
    t.float   "probability"
  end

  create_table "topics", :force => true do |t|
    t.string  "name"
    t.integer "orig_run_id"
    t.integer "run_id"
  end

  create_table "user_reports", :force => true do |t|
    t.string   "subject_type"
    t.text     "content"
    t.integer  "subject_id"
    t.integer  "user_id"
    t.text     "report"
    t.datetime "created_at"
  end

  create_table "users", :force => true do |t|
    t.string   "openid_url"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_seen_at"
    t.string   "username"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.integer  "downloads_count",                         :default => 0
    t.integer  "viewings_count",                          :default => 0
    t.string   "email"
    t.string   "unconfirmed_email"
    t.datetime "email_confirmed_at"
    t.datetime "activated_at"
    t.boolean  "receive_notifications",                   :default => true
    t.string   "reset_password_code"
    t.datetime "reset_password_code_until"
    t.string   "account_status"
    t.integer  "spam_score"
  end

  create_table "viewings", :force => true do |t|
    t.integer  "contribution_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.string   "user_agent"
    t.boolean  "accessed_from_site", :default => false
  end

  add_index "viewings", ["contribution_id"], :name => "index_viewings_on_contribution_id"

  create_table "vocabularies", :force => true do |t|
    t.integer  "user_id"
    t.string   "title"
    t.text     "description"
    t.text     "description_html"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "prefix"
    t.string   "uri"
  end

  create_table "workflow_processors", :force => true do |t|
    t.string  "name"
    t.string  "wsdl_operation"
    t.string  "wsdl"
    t.integer "workflow_id"
  end

  create_table "workflow_versions", :force => true do |t|
    t.integer  "workflow_id"
    t.integer  "version"
    t.integer  "contributor_id"
    t.string   "contributor_type"
    t.string   "title"
    t.string   "unique_name"
    t.text     "body"
    t.text     "body_html"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image"
    t.string   "svg"
    t.text     "revision_comments"
    t.integer  "content_blob_id"
    t.string   "file_ext"
    t.string   "last_edited_by"
    t.integer  "content_type_id"
    t.string   "license"
    t.integer  "preview_id"
  end

  add_index "workflow_versions", ["workflow_id"], :name => "index_workflow_versions_on_workflow_id"

  create_table "workflows", :force => true do |t|
    t.integer  "contributor_id"
    t.string   "contributor_type"
    t.string   "image"
    t.string   "svg"
    t.string   "title"
    t.string   "unique_name"
    t.text     "body"
    t.text     "body_html"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "current_version"
    t.integer  "content_blob_id"
    t.string   "file_ext"
    t.string   "last_edited_by"
    t.integer  "content_type_id"
    t.integer  "license_id"
    t.integer  "preview_id"
  end

end
