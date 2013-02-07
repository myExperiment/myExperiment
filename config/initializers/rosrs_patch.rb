
class ROSRS::RDFGraph
  attr_accessor :graph
end

# resource_uri handling is different in that if it is nil then it will return
# all annotation statements for the entire RO

class ROSRS::Session
  def get_annotation_statements(ro_uri, resource_uri=nil)
    manifesturi, manifest = get_manifest(ro_uri)
    statements = []

    resource_uri = RDF::URI.parse(ro_uri).join(RDF::URI.parse(resource_uri)) if ro_uri && resource_uri

    manifest.query(:object => resource_uri) do |stmt|
      if [RDF::AO.annotatesResource,RDF::RO.annotatesAggregatedResource].include?(stmt.predicate)
        statements << stmt
      end
    end
    statements
  end
end

# ROTERMS in the gem has the wrong base URI

module RDF
  class ROTERMS2 < Vocabulary("http://purl.org/wf4ever/roterms#")
    property :note
    property :resource
    property :defaultBase
  end
end

