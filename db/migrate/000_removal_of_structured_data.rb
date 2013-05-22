class RemovalOfStructuredData < ActiveRecord::Migration
  def self.up

    # Don't create these tables in if the (now removed) structured_data plugin
    # has already created them.

    return if ActiveRecord::Base.connection.tables.include?("contributions")

    create_table "concept_relations" do |t|
      t.integer "subject_concept_id"
      t.string  "relation_type"
      t.integer "object_concept_id"
    end

    create_table "concepts" do |t|
      t.datetime "updated_at"
      t.text     "description_html"
      t.string   "phrase"
      t.text     "description"
      t.integer  "vocabulary_id"
      t.datetime "created_at"
    end

    create_table "content_types" do |t|
      t.integer  "user_id"
      t.string   "title"
      t.text     "description"
      t.text     "description_html"
      t.string   "mime_type"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "category"
    end

    create_table "contributions" do |t|
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

    add_index "contributions",     ["contributable_id", "contributable_type"]
    add_index "contributions",     ["contributor_id", "contributor_type"]

    create_table "downloads" do |t|
      t.integer  "contribution_id"
      t.integer  "user_id"
      t.datetime "created_at"
      t.string   "user_agent"
      t.boolean  "accessed_from_site", :default => false
      t.string   "kind"
    end

    add_index :downloads, ["contribution_id"]

    create_table "federation_sources" do |t|
      t.string "name"
    end

    create_table "labels" do |t|
      t.integer "concept_id"
      t.string  "language"
      t.string  "text"
      t.integer "vocabulary_id"
      t.string  "label_type"
    end

    create_table "ontologies" do |t|
      t.string   "prefix"
      t.datetime "updated_at"
      t.string   "uri"
      t.string   "title"
      t.text     "description_html"
      t.text     "description"
      t.integer  "user_id"
      t.datetime "created_at"
    end

    create_table "pack_contributable_entries" do |t|
      t.integer  "pack_id",               :null => false
      t.integer  "contributable_id",      :null => false
      t.integer  "contributable_version"
      t.string   "contributable_type"
      t.text     "comment"
      t.integer  "user_id",               :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "pack_remote_entries" do |t|
      t.integer  "pack_id",       :null => false
      t.string   "title"
      t.string   "uri"
      t.string   "alternate_uri"
      t.text     "comment"
      t.integer  "user_id",       :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "packs" do |t|
      t.integer  "contributor_id"
      t.string   "contributor_type"
      t.string   "title"
      t.text     "description"
      t.text     "description_html"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "policies" do |t|
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

    create_table "predicates" do |t|
      t.datetime "updated_at"
      t.string   "title"
      t.text     "description_html"
      t.string   "phrase"
      t.integer  "ontology_id"
      t.text     "description"
      t.text     "equivalent_to"
      t.datetime "created_at"
    end

    create_table "previews" do |t|
      t.integer  "svg_blob_id"
      t.integer  "image_blob_id"
      t.datetime "created_at"
    end

    create_table "relationships" do |t|
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

    create_table "service_categories" do |t|
      t.string   "uri"
      t.datetime "updated_at"
      t.integer  "service_id"
      t.string   "label"
      t.datetime "retrieved_at"
      t.datetime "created_at"
    end

    create_table "service_deployments" do |t|
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

    create_table "service_providers" do |t|
      t.string   "name"
      t.string   "uri"
      t.datetime "updated_at"
      t.text     "description"
      t.datetime "created"
      t.datetime "retrieved_at"
      t.datetime "created_at"
    end

    create_table "service_tags" do |t|
      t.string   "uri"
      t.datetime "updated_at"
      t.integer  "service_id"
      t.string   "label"
      t.datetime "retrieved_at"
      t.datetime "created_at"
    end

    create_table "service_types" do |t|
      t.datetime "updated_at"
      t.integer  "service_id"
      t.string   "label"
      t.datetime "retrieved_at"
      t.datetime "created_at"
    end

    create_table "services" do |t|
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

    create_table "topic_feedbacks" do |t|
      t.integer  "score"
      t.integer  "topic_id"
      t.datetime "submit_dt"
      t.integer  "user_id"
    end

    create_table "topic_runs" do |t|
      t.datetime "runtime"
      t.string   "description"
    end

    create_table "topic_tag_map" do |t|
      t.integer "topic_id"
      t.boolean "display_flag"
      t.integer "tag_id"
      t.float   "probability"
    end

    create_table "topic_workflow_map" do |t|
      t.integer "topic_id"
      t.boolean "display_flag"
      t.integer "workflow_id"
      t.float   "probability"
    end

    create_table "topics" do |t|
      t.string  "name"
      t.integer "orig_run_id"
      t.integer "run_id"
    end

    create_table "user_reports" do |t|
      t.string   "subject_type"
      t.text     "content"
      t.integer  "subject_id"
      t.integer  "user_id"
      t.text     "report"
      t.datetime "created_at"
    end

    create_table "vocabularies" do |t|
      t.integer  "user_id"
      t.string   "title"
      t.text     "description"
      t.text     "description_html"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "prefix"
      t.string   "uri"
    end

    create_table "workflow_processors" do |t|
      t.string  "name"
      t.string  "wsdl_operation"
      t.string  "wsdl"
      t.integer "workflow_id"
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration 
  end
end

