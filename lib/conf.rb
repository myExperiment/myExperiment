# myExperiment: lib/conf.rb
# 
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

# Configuration module

require 'yaml'

class Conf

  @vars = YAML::load_file("config/settings.yml")

  def self.sitename
    @vars['site_name']
  end

  def self.site_logo
    @vars['site_logo']
  end

  def self.notifications_email_address
    @vars['notifications_email_address']
  end

  def self.feedback_email_address
    @vars['feedback_email_address']
  end

  def self.base_uri
    @vars['base_uri']
  end

  def self.admins
    @vars['admins']
  end

  def self.main_tabs
    @vars['main_tabs']
  end

  def self.new_menu
    @vars['new_menu']
  end

  # This method is required to create an administrator in the test fixtures

  def self.admins=(value)
    @vars['admins'] = value
  end

end

