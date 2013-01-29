# myExperiment: app/helpers/research_objects_helper.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

module ResearchObjectsHelper

  def research_object_summary(ro)

    s_uris = []
    p_uris = []
    o_uris = []

    ro.statements.each do |statement|
      s_uris << statement.subject_text
      p_uris << statement.predicate_text
      o_uris << statement.objekt_text
    end

    uris = (s_uris + p_uris + o_uris).uniq!
    
    uris.map! do |uri|
      [uri, s_uris.select do |u| u == uri end.length,
            p_uris.select do |u| u == uri end.length,
            o_uris.select do |u| u == uri end.length]
    end

    uris.sort! do |a, b|
      by_count = (b[1] + b[2] + b[3]) <=> (a[1] + a[2] + a[3])

      if by_count == 0
        b[0] <=> a[0]
      else
        by_count
      end
    end

    uris
  end


  def get_annotations(ro_uri, resource_uri)
    session = ROSRS::Session.new(ro_uri, Conf.rodl_bearer_token)
    session.get_annotation_graph(ro_uri, resource_uri)
  end
  
  def get_annotation_graphs(ro_uri, resource_uri)
    session = ROSRS::Session.new(ro_uri, Conf.rodl_bearer_token)
    session.get_annotation_graphs(ro_uri, resource_uri)
  end
  
  def resource_types(annotations, resource_uri)
    annotations.graph.query([RDF::URI(resource_uri), RDF::type, nil]).map do |s,p,type|
      type.to_s
    end
  end
  
  def resource_types_as_labels(annotations, resource_uri)
    resource_types(annotations, resource_uri).map do |type_uri|
      textual_type(type_uri) or type_uri
    end    
  end
  
  def textual_type(typeuri)
    type = Conf.ro_resource_types.rassoc(typeuri)
    type.first if type
  end
  
  def research_object_statements(contributable)

    return [] unless contributable.respond_to?(:content_blob)

    hash = contributable.content_blob.md5
    
    statements = Statement.find(:all,
        :joins      => "JOIN statements AS a1 ON statements.subject_text = a1.subject_text",
        :conditions => ["a1.predicate_text = ? AND a1.objekt_text = ?",
                        "http://purl.org/wf4ever/ro#checksum",
                        "urn:MD5:#{hash.upcase}"])
  end

  def research_object_resources(contributable)

    markup = "<ul class='research_object_browser'>"

    contributable.wf4ever_resources.each do |resource|
      markup += "<li>#{link_to(resource[:name], research_object_resource_path(contributable, resource[:name]))}</li>"
    end

    markup += "</ul>"

    markup
  end

end
