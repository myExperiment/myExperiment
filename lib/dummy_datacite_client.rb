# myExperiment: lib/dummy_datacite_client.rb
#
# Copyright (c) 2015 University of Manchester and the University of Southampton.
# See license.txt for details.

# For test purposes

class DummyDataciteClient

  def initialize
    @metadata = {}
    @dois = {}
  end

  def upload_metadata(metadata_xml)
    hash = Hash.from_xml(metadata_xml)
    @metadata[hash["resource"]["identifier"]] = hash
    "OK (#{hash["resource"]["identifier"]})"
  end

  def mint(doi, url)
    @dois[doi] = url
    "OK"
  end

  def resolve(doi)
    @dois[doi]
  end
  
end
