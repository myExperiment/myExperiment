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

  def self.notifications_email_address
    self.fetch_entry('notifications_email_address')
  end

  def self.feedback_email_address
    self.fetch_entry('feedback_email_address')
  end

  def self.base_uri
    self.fetch_entry('base_uri')
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

  # This method is required to create an administrator in the test fixtures

  def self.admins=(value)
    @settings['admins'] = value
  end

private

  def self.fetch_entry(key, default = nil)
    return @settings[key] if @settings[key]
    return @defaults[key] if @defaults[key]
    default
  end

end

