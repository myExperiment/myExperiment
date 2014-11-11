# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140903091202) do

  create_table "activities", :force => true do |t|
    t.string   "subject_type"
    t.integer  "subject_id"
    t.string   "subject_label"
    t.string   "action"
    t.string   "objekt_type"
    t.integer  "objekt_id"
    t.string   "objekt_label"
    t.string   "context_type"
    t.integer  "context_id"
    t.string   "auth_type"
    t.integer  "auth_id"
    t.string   "extra"
    t.string   "uuid"
    t.integer  "priority",      :default => 0
    t.boolean  "featured",      :default => false
    t.boolean  "hidden",        :default => false
    t.datetime "timestamp"
  end

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

  create_table "annotation_resources", :force => true do |t|
    t.integer "research_object_id"
    t.integer "annotation_id"
    t.string  "resource_path"
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
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.binary  "data", :limit => 2147483647
    t.string  "md5",  :limit => 32
    t.string  "sha1", :limit => 40
    t.integer "size"
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

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "queue"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "deprecation_events", :force => true do |t|
    t.string   "title"
    t.datetime "date"
    t.text     "details"
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

  create_table "federation_sources", :force => true do |t|
    t.string "name"
  end

  create_table "feed_items", :force => true do |t|
    t.integer  "feed_id"
    t.string   "identifier"
    t.string   "title"
    t.text     "content"
    t.string   "author"
    t.string   "link"
    t.datetime "item_published_at"
    t.datetime "item_updated_at"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "feeds", :force => true do |t|
    t.string   "title"
    t.text     "uri"
    t.string   "context_type"
    t.integer  "context_id"
    t.string   "username"
    t.string   "password"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.integer  "version"
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
    t.integer  "version"
  end

  create_table "pack_versions", :force => true do |t|
    t.integer  "pack_id"
    t.integer  "version"
    t.text     "revision_comments"
    t.string   "title"
    t.text     "description"
    t.text     "description_html"
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
    t.integer  "current_version"
    t.integer  "license_id"
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
    t.string   "layout"
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

  create_table "research_objects", :force => true do |t|
    t.string   "context_type"
    t.integer  "context_id"
    t.string   "slug"
    t.integer  "version"
    t.string   "version_type"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "resources", :force => true do |t|
    t.integer  "research_object_id"
    t.string   "context_type"
    t.integer  "context_id"
    t.integer  "content_blob_id"
    t.string   "sha1",               :limit => 40
    t.integer  "size"
    t.string   "content_type"
    t.text     "path"
    t.string   "entry_name"
    t.string   "creator_uri"
    t.string   "uuid",               :limit => 36
    t.string   "proxy_in_path"
    t.string   "proxy_for_path"
    t.string   "ao_body_path"
    t.string   "resource_map_path"
    t.string   "aggregated_by_path"
    t.boolean  "is_resource",                      :default => false
    t.boolean  "is_aggregated",                    :default => false
    t.boolean  "is_proxy",                         :default => false
    t.boolean  "is_annotation",                    :default => false
    t.boolean  "is_resource_map",                  :default => false
    t.boolean  "is_folder",                        :default => false
    t.boolean  "is_folder_entry",                  :default => false
    t.boolean  "is_root_folder",                   :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
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

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "subscriptions", :force => true do |t|
    t.integer "user_id"
    t.string  "objekt_type"
    t.integer "objekt_id"
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.datetime "created_at"
    t.string   "tagger_type",                  :default => "User"
    t.string   "context",       :limit => 128, :default => "tags"
  end

  add_index "taggings", ["tag_id", "taggable_type"], :name => "index_taggings_on_tag_id_and_taggable_type"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"
  add_index "taggings", ["tagger_id", "tag_id", "taggable_type"], :name => "index_taggings_on_user_id_and_tag_id_and_taggable_type"
  add_index "taggings", ["tagger_id", "taggable_id", "taggable_type"], :name => "index_taggings_on_user_id_and_taggable_id_and_taggable_type"

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
    t.string   "given_name"
    t.string   "family_name"
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

  create_table "workflow_ports", :force => true do |t|
    t.string  "name"
    t.string  "port_type"
    t.integer "workflow_id"
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
    t.string   "license"
    t.integer  "preview_id"
    t.string   "image"
    t.string   "svg"
    t.text     "revision_comments"
    t.integer  "content_blob_id"
    t.string   "file_ext"
    t.string   "last_edited_by"
    t.integer  "content_type_id"
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
    t.integer  "current_version"
    t.integer  "preview_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "content_blob_id"
    t.string   "file_ext"
    t.string   "last_edited_by"
    t.integer  "content_type_id"
    t.integer  "license_id"
  end

  create_table "wsdl_deprecations", :force => true do |t|
    t.string  "wsdl"
    t.integer "deprecation_event_id"
  end

end
