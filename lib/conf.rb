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

  # This method is required to create an administrator in the test fixtures

  def self.admins=(value)
    @settings['admins'] = value
  end

private

  def self.fetch_entry(key)
    return @settings[key] if @settings[key]
    return @defaults[key] if @defaults[key]
  end

end

