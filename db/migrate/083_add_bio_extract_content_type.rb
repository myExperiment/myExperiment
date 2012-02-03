# myExperiment: 083_add_bio_extract_content_type.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

class AddBioExtractContentType < ActiveRecord::Migration

  def self.up
    if ContentType.find_by_title("BioExtract Server").nil?
      ContentType.create(:title => 'BioExtract Server', :mime_type => 'application/xml')
    end
  end

  def self.down
  end
end

