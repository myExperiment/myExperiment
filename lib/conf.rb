# myExperiment: lib/conf.rb
# 
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

# Configuration module

require 'yaml'

class Conf

  @defaults = YAML::load_file("config/default_settings.yml")

  if File.exists?("config/settings.yml")
    @settings = YAML::load_file("config/settings.yml")
  else
    @settings = {}
  end

  def self.sitename
    self.fetch_entry('site_name')
  end

  def self.site_logo
    self.fetch_entry('site_logo')
  end

  def self.site_logo_cropped
    self.fetch_entry('site_logo_cropped')
  end

  def self.contributor_models
    self.fetch_entry('contributor_models')
  end

  def self.contributable_models
    self.fetch_entry('contributable_models')
  end

  def self.notifications_email_address
    self.fetch_entry('notifications_email_address')
  end

  def self.feedback_email_address
    self.fetch_entry('feedback_email_address')
  end

  def self.base_uri
    if Rails.env == 'test'
      "http://test.host"
    else
      self.fetch_entry('base_uri')
    end
  end

  def self.hostname
    uri = URI(Conf.base_uri)

    host = uri.host
    unless uri.port == uri.default_port
      host += ":#{uri.port}"
    end

    host
  end

  def self.admins
    self.fetch_entry('admins')
  end

  def self.curators
    self.fetch_entry('curators')
  end

  def self.main_tabs
    self.fetch_entry('main_tabs')
  end

  def self.new_menu
    self.fetch_entry('new_menu')
  end

  def self.search_categories
    self.fetch_entry('search_categories')
  end

  def self.model_aliases
    self.fetch_entry('model_aliases')
  end

  def self.bot_ignore_list
    self.fetch_entry('bot_ignore_list')
  end

  def self.max_upload_size
    self.fetch_entry('max_upload_size')
  end

  def self.solr_enable
    self.fetch_entry('solr_enable')
  end

  def self.smtp
    self.fetch_entry('smtp')
  end

  def self.show_debug
    self.fetch_entry('show_debug')
  end

  def self.sym_encryption_key
    self.fetch_entry('sym_encryption_key')
  end

  def self.secret_word
    self.fetch_entry('secret_word')
  end

  def self.google_web_analytics
    self.fetch_entry('google_web_analytics')
  end

  def self.bookmark_widget
    self.fetch_entry('bookmark_widget')
  end

  def self.activity_limits
    self.fetch_entry('activity_limits')
  end

  def self.home_page_stats
    self.fetch_entry('home_page_stats')
  end

  def self.label_icons
    self.fetch_entry('label_icons', {})
  end
  
  def self.default_search_size
    self.fetch_entry('default_search_size')
  end

  def self.max_search_size
    self.fetch_entry('max_search_size')
  end

  def self.curation_types
    self.fetch_entry('curation_types')
  end

  def self.page_template
    self.fetch_entry('page_template')
  end

  def self.stylesheet
    self.fetch_entry('stylesheet')
  end

  def self.rdfgen_enable
    self.fetch_entry('rdfgen_enable')
  end

  def self.rdfgen_tool
    self.fetch_entry('rdfgen_tool')
  end

  def self.recaptcha_enable
    self.fetch_entry('recaptcha_enable')
  end

  def self.recaptcha_public
    self.fetch_entry('recaptcha_public')
  end

  def self.recaptcha_private
    self.fetch_entry('recaptcha_private')
  end

  def self.session_store_secret
    self.fetch_entry('session_store_secret')
  end

  def self.cookie_verifier_secret
    self.fetch_entry('cookie_verifier_secret')
  end

  def self.duplicable_mime_types
    self.fetch_entry('duplicable_mime_types')
  end

  def self.deleted_data_directory
    self.fetch_entry('deleted_data_directory')
  end

  def self.spam_patterns
    self.fetch_entry('spam_patterns')
  end

  def self.layouts
    layouts = self.fetch_entry('layouts', {})
    layouts.delete_if {|k,v| v["environment"] && (v["environment"] != Rails.env)}
  end

  def self.external_site_integrations
    self.fetch_entry('site_integrations',{})
  end

  def self.pivot_options
    self.fetch_entry('pivot_options', {})
  end

  def self.enable_triple_store
    self.fetch_entry('enable_triple_store')
  end

  def self.sesame_repository
    self.fetch_entry('sesame_repository')
  end

  def self.initial_filter_size
    self.fetch_entry('initial_filter_size')
  end

  def self.expanded_filter_size
    self.fetch_entry('expanded_filter_size')
  end

  def self.enable_online_hpc
    self.fetch_entry('enable_online_hpc')
  end

  def self.online_hpc_url
    self.fetch_entry('online_hpc_url')
  end

  def self.datacite_enabled?
    self.fetch_entry('enable_datacite')
  end

  def self.datacite_url
    self.fetch_entry('datacite_url')
  end

  def self.datacite_username
    self.fetch_entry('datacite_username')
  end

  def self.datacite_password
    self.fetch_entry('datacite_password')
  end

  def self.doi_prefix
    self.fetch_entry('doi_prefix')
  end

  def self.systo_execution_enabled?
    self.fetch_entry('enable_systo_execution')
  end

  def self.systo_execution_url
    self.fetch_entry('systo_execution_url')
  end

  def self.method_missing(method)
    if @defaults.has_key?(method.to_s)
      fetch_entry(method.to_s)
    else
      super
    end
  end

  # This method is required to create an administrator in the test fixtures

  def self.admins=(value)
    @settings['admins'] = value
  end

  def self.set_configuration(request, session)

    @config = nil

    if request.class.name != "ActionController::TestRequest"
      if @settings['virtual_hosts']
        @settings['virtual_hosts'].each do |name, settings|

          if settings['entry_point'] && request.referer && settings['entry_point']
            if request.referer == settings['entry_point']
              session["portal"] = name
            end
          end

          if settings['host'] && request.host == settings['host']
            @config = name
          end

          if settings['prefix'] && request.path.starts_with?(settings['prefix'])
            remainder = request.path[settings['prefix'].length..-1]

            if remainder.empty? || remainder.match(/^[.\/]/)
              @config = name
            end
          end
        end
      end
    end

    if request.query_parameters['portal_url']
      session['portal_url'] = request.query_parameters['portal_url']
    end

    @config = session["portal"] if session["portal"]
  end

  # helper function to convert model aliases

  def self.to_model(str)
    self.model_alias_convert(self.model_aliases, str)
  end

  def self.to_visible(str)
    self.model_alias_convert(self.model_aliases.invert, str)
  end

  def self.shortcut_keywords
    self.fetch_entry('shortcut_keywords') || {}
  end

private

  def self.model_alias_convert(map, str)
    map.each do |k, v|
      return v                      if str == k
      return v.underscore           if str == k.underscore
      return v.pluralize            if str == k.pluralize
      return v.underscore.pluralize if str == k.underscore.pluralize
    end

    str
  end

  def self.fetch_entry(key, default = nil)
    return @settings[key] if @settings[key]
    return @defaults[key] if @defaults[key]

    default
  end
end

