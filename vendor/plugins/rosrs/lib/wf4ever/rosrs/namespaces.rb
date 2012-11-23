#:nodoc: all

module RDF

  class AO < Vocabulary("http://purl.org/ao/")
    # Declaring these might not be necessary
    property :Annotation
    property :body
    property :annotatesResource
  end

  class ORE < Vocabulary("http://www.openarchives.org/ore/terms/")
    property :Aggregation
    property :AggregatedResource
    property :Proxy
    property :aggregates
    property :proxyFor
    property :proxyIn
    property :isDescribedBy
  end

  class RO < Vocabulary("http://purl.org/wf4ever/ro#")
    property :ResearchObject
    property :AggregatedAnnotation
    property :annotatesAggregatedResource
    property :FolderEntry
    property :Folder
    property :Resource
    property :entryName
  end

  class ROEVO < Vocabulary("http://purl.org/wf4ever/roevo#")
    property :LiveRO
  end

  class ROTERMS < Vocabulary("http://ro.example.org/ro/terms/")
    property :note
    property :resource
    property :defaultBase
  end

  class DON < Vocabulary("http://example.com/2012/11/workflow#")
    property :hasExampleDataSet
    property :dataSet
    property :hasInput
    property :input
    property :value
  end

end
