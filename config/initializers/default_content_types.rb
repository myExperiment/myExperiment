# myExperiment: config/initializers/content_types.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

# Loads a set default content_types into the database

content_types = YAML::load_file("config/content_types.yml")

Rails.logger.debug('Loading content types...')
ContentType.transaction do
  content_types.each do |k,v|
    unless ContentType.find_by_title_and_mime_type_and_category(v['title'], v['mime_type'], v['category'])
      Rails.logger.debug("\tCreating content type #{v['title']}: #{v['mime_type']}")
      ContentType.create(v)
    end
  end
end
