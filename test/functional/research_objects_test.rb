# myExperiment: test/functional/research_objects_test.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

require_relative '../test_helper'

class ResearchObjectsTest < ActionController::IntegrationTest

  include ResearchObjectsHelper

  fixtures :all

  def setup
    host!("test.host")
  end
#
#   test "creation and deletion of research objects" do
#
#     ros_uri      = research_objects_url
#     ro_uri       = research_object_url('test_ro') + "/"
#     manifest_uri = ro_uri + ResearchObject::MANIFEST_PATH
#
#     # Test that the index of research objects equals the test packs
#
#     get research_objects_path
#
#     fixture_ros =
#       "http://test.host/rodl/ROs/Pack1/\n" +
#       "http://test.host/rodl/ROs/Pack2/\n" +
#       "http://test.host/rodl/ROs/Pack3/\n" +
#       "http://test.host/rodl/ROs/Pack4/\n" +
#       "http://test.host/rodl/ROs/Pack5/\n"
#
#     assert_response :ok
#     assert_equal fixture_ros, @response.body
#     assert_equal "text/uri-list", @response.content_type
#
#     # Create a research object.
#
#     post research_objects_path, {}, { "HTTP_SLUG" => "test_ro" }
#
#     assert_response :created
#     assert_equal ro_uri, @response.headers["Location"]
#
#     # Test that you can't create another RO at the same location
#
#     post research_objects_path, {}, { "HTTP_SLUG" => "test_ro" }
#
#     assert_response :conflict
#
#     # Test that the index now contains the new research object.
#
#     get research_objects_path
#
#     assert_response :ok
#     assert_equal "#{fixture_ros}#{ro_uri}\n", @response.body
#     assert_equal "text/uri-list", @response.content_type
#
#     # Test the manifest redirection.
#
#     get ro_uri, {}, { "HTTP_ACCEPT" => "application/rdf+xml" }
#
#     assert_response :see_other
#     assert_equal manifest_uri, @response.headers["Location"]
#
#     # Get the manifest.
#
#     get manifest_uri
#
#     assert_response :ok
#
#     # Delete the test RO.
#
#     delete ro_uri
#
#     assert_response :no_content
#
#     # Try to get the deleted research object.
#
#     get ro_uri
#
#     assert_response :not_found
#
#     # Try to get the manifest of the deleted research object.
#
#     get manifest_uri
#
#     assert_response :not_found
#
#     # Delete the non-existent RO.
#
#     delete ro_uri
#
#     assert_response :not_found
#
#   end
#
#   test "manifest statements of a newly created research object" do
#
#     # Create a new research object and get the manifest
#
#     post research_objects_path, {}, { "HTTP_SLUG" => "test_ro" }
#
#     assert_response :created
#     assert_equal research_object_url('test_ro') + "/", @response.headers["Location"]
#
#     get research_object_resource_path('test_ro', '.ro/manifest.rdf')
#
#     assert_response :ok
#
#     # Parse the graph and ensure that it has statements
#
#     graph = RDF::Graph.new
#     graph << RDF::Reader.for(:rdfxml).new(@response.body)
#
#     ro_uri = RDF::URI(research_object_url('test_ro')) + "/"
#
#     assert_operator 0, :<, graph.count
#
#     # Test that the creator of the RO is correct
#
#     assert_equal user_url(users(:john)), graph.query([ro_uri, RDF::DC.creator, nil]).first_object
#
#     # Test that the date has the correct datatype and within reason
#
#     assert_equal RDF::XSD.dateTime, graph.query([ro_uri, RDF::DC.created, nil]).first_object.datatype
#
#     created = DateTime.parse(graph.query([ro_uri, RDF::DC.created, nil]).first_object.value)
#
#     assert_operator DateTime.parse("2000-01-01"), :<, created
#     assert_operator DateTime.parse("3000-01-01"), :>, created
#
#   end
#
#   test "automatic generation of proxies for generic resources" do
#
#     # Create the test RO.
#
#     post research_objects_path, {}, { "HTTP_SLUG" => "test_ro" }
#     assert_response :created
#
#     # Create the resource and check the response is the proxy
#
#     post research_object_path('test_ro'), "Hello World.\n", { "HTTP_SLUG" => "test_resource.txt", "CONTENT_TYPE" => "text/plain" }
#
#     assert_response :created
#     assert_equal "application/rdf+xml", @response.content_type.to_s
#
#     links = parse_links(@response.headers)
#
#     resource_uri = links["http://www.openarchives.org/ore/terms/proxyFor"].first
#
#     assert_equal research_object_resource_url("test_ro", "test_resource.txt"), resource_uri
#
#     graph = RDF::Graph.new
#     graph << RDF::Reader.for(:rdfxml).new(@response.body)
#
#     assert_equal 1, graph.query([nil, RDF.type, RDF::URI("http://www.openarchives.org/ore/terms/Proxy")]).count
#
#     proxy_uri = graph.query([nil, RDF::URI("http://www.openarchives.org/ore/terms/proxyFor"), RDF::URI(resource_uri)]).first_subject.to_s
#
#     # Confirm that the resource was created.
#
#     get resource_uri
#
#     assert_response :ok
#     assert_equal "Hello World.\n", @response.body
#     assert_equal "text/plain", @response.content_type.to_s
#
#     # Confirm that a proxy was created automatically and that the proxy graph is correct.
#
#     get proxy_uri
#
#     assert_response :see_other
#
#     graph2 = RDF::Graph.new
#     graph2 << RDF::Reader.for(:rdfxml).new(@response.body)
#
#     assert graph2.query([
#         RDF::URI(proxy_uri),
#         RDF::URI("http://www.openarchives.org/ore/terms/proxyFor"),
#         RDF::URI(resource_uri)
#         ])
#
#     assert graph2.query([
#         RDF::URI(proxy_uri),
#         RDF.type,
#         RDF::URI("http://www.openarchives.org/ore/terms/Proxy")
#         ])
#
#     assert graph2.query([
#         RDF::URI(proxy_uri),
#         RDF::URI("http://www.openarchives.org/ore/terms/proxyIn"),
#         RDF::URI(research_object_url("test_ro") + "/")
#         ])
#   end
#
#   test "disallow overwriting of the manifest" do
#
#     # Create the test RO.
#
#     post research_objects_path, {}, { "HTTP_SLUG" => "test_ro" }
#     assert_response :created
#
#     # Create a resource and try to overwrite the manifest
#
#     post research_object_path('test_ro'), "Hello World.\n", { "HTTP_SLUG" => ResearchObject::MANIFEST_PATH, "CONTENT_TYPE" => "text/plain" }
#     assert_response :forbidden
#   end
#
#   test "creation of a proxy for an external resource" do
#
#     # Create the test RO.
#
#     post research_objects_path, {}, { "HTTP_SLUG" => "test_ro" }
#
#     assert_response :created
#
#     ro_uri = @response.location
#
#     # Create a proxy by providing a proxy description with an ore:proxyFor term.
#
#     external_resource_uri = "http://elsewhere.example.com/external_resource.txt"
#
#     test_proxy_description = %Q(
#       <rdf:RDF
#           xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
#           xmlns:ore="http://www.openarchives.org/ore/terms/" >
#
#         <rdf:Description>
#           <ore:proxyFor rdf:resource="#{external_resource_uri}"/>
#           <rdf:type rdf:resource="http://www.openarchives.org/ore/terms/Proxy"/>
#         </rdf:Description>
#
#       </rdf:RDF>
#     )
#
#     post(research_object_path('test_ro'),
#         test_proxy_description,
#         { "CONTENT_TYPE" => "application/vnd.wf4ever.proxy" })
#
#     links = parse_links(@response.headers)
#
#     proxy_for_uri = links["http://www.openarchives.org/ore/terms/proxyFor"].first
#     proxy_uri = @response.location
#
#     graph = load_graph(@response.body)
#
#     # Check ore:proxyFor link
#
#     assert_equal(external_resource_uri, proxy_for_uri)
#
#     # Check the returned RDF for the appropriate proxy statements
#
#     assert_equal 1, graph.query([RDF::URI(proxy_uri), RDF.type, ORE.Proxy]).count
#     assert_equal 1, graph.query([RDF::URI(proxy_uri), ORE.proxyFor, RDF::URI(proxy_for_uri)]).count
#     assert_equal 1, graph.query([RDF::URI(proxy_uri), ORE.proxyIn, RDF::URI(ro_uri)]).count
#
#     # Check the manifest for the appropriate proxy statements
#
#     get ro_uri + ResearchObject::MANIFEST_PATH
#     assert_response :ok
#
#     manifest_graph = load_graph(@response.body)
#
#     assert_equal 1, manifest_graph.query([RDF::URI(proxy_uri), RDF.type, ORE.Proxy]).count
#     assert_equal 1, manifest_graph.query([RDF::URI(proxy_uri), ORE.proxyFor, RDF::URI(proxy_for_uri)]).count
#     assert_equal 1, manifest_graph.query([RDF::URI(proxy_uri), ORE.proxyIn, RDF::URI(ro_uri)]).count
#   end
#
#   test "creation of a folder" do
#
#     # Create the test RO.
#
#     post research_objects_path, {}, { "HTTP_SLUG" => "test_ro" }
#
#     assert_response :created
#
#     ro_uri = @response.location
#
#     # Create the folder
#
#     test_folder_description = %Q(
#       <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" >
#         <rdf:Description>
#           <rdf:type rdf:resource="http://purl.org/wf4ever/ro#Folder"/>
#         </rdf:Description>
#       </rdf:RDF>
#     )
#
#     test_folder_path = "test_folder/"
#
#     test_folder_uri = RDF::URI(ro_uri) + test_folder_path
#
#     post(research_object_path('test_ro'),
#         test_folder_description,
#         { "CONTENT_TYPE" => "application/vnd.wf4ever.folder",
#           "SLUG"         =>  test_folder_path })
#
#     assert_response :created
#
#     links = parse_links(@response.headers)
#
#     proxy_for_uri   = links["http://www.openarchives.org/ore/terms/proxyFor"].first
#     is_described_by = links["http://www.openarchives.org/ore/terms/isDescribedBy"].first
#
#     proxy_uri = @response.location
#
#     graph = load_graph(@response.body)
#
#     resource_map_uri = graph.query([test_folder_uri, ORE.isDescribedBy, nil]).first_object
#
#     assert resource_map_uri
#
#     # Assert the link and location headers match up with the response RDF
#
#     assert_equal 1, graph.query([RDF::URI(proxy_uri), RDF.type, ORE.Proxy]).count
#     assert_equal 1, graph.query([RDF::URI(proxy_uri), ORE.proxyFor, test_folder_uri]).count
#     assert_equal 1, graph.query([resource_map_uri, ORE.describes, test_folder_uri]).count
#
#     # Assert the statements in the manifest.
#
#     get ro_uri + ResearchObject::MANIFEST_PATH
#     assert_response :ok
#
#     manifest_graph = load_graph(@response.body)
#
#     assert_equal 1, manifest_graph.query([RDF::URI(proxy_uri), RDF.type, ORE.Proxy]).count
#     assert_equal 1, manifest_graph.query([RDF::URI(proxy_uri), ORE.proxyFor, test_folder_uri]).count
#     assert_equal 1, manifest_graph.query([resource_map_uri, ORE.describes, test_folder_uri]).count
#   end
#
#   test "creation of a folder entry" do
#
#     # Create the test RO.
#
#     post research_objects_path, {}, { "HTTP_SLUG" => "test_ro" }
#
#     assert_response :created
#
#     ro_uri = @response.location
#
#     # Create the folder
#
#     test_folder_description = %Q(
#       <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" >
#         <rdf:Description>
#           <rdf:type rdf:resource="http://purl.org/wf4ever/ro#Folder"/>
#         </rdf:Description>
#       </rdf:RDF>
#     )
#
#     test_folder_path = "test_folder/"
#
#     test_folder_uri = RDF::URI(ro_uri) + test_folder_path
#
#     post(research_object_path('test_ro'),
#         test_folder_description,
#         { "CONTENT_TYPE" => "application/vnd.wf4ever.folder",
#           "SLUG"         =>  test_folder_path })
#
#     assert_response :created
#
#     # Create the folder entry
#
#     test_folder_description = %Q(
#       <rdf:RDF
#           xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
#           xmlns:ore="http://www.openarchives.org/ore/terms/" >
#
#         <rdf:Description>
#           <rdf:type rdf:resource="http://purl.org/wf4ever/ro#FolderEntry"/>
#           <ore:proxyFor rdf:resource="#{test_folder_uri}"/>
#         </rdf:Description>
#       </rdf:RDF>
#     )
#
#
# #   proxy_for_uri   = links["http://www.openarchives.org/ore/terms/proxyFor"].first
# #   is_described_by = links["http://www.openarchives.org/ore/terms/isDescribedBy"].first
#
# #   proxy_uri = @response.location
#
# #   graph = load_graph(@response.body)
#
# #   resource_map_uri = graph.query([test_folder_uri, ORE.isDescribedBy, nil]).first_object
#
# #   assert resource_map_uri
#
# #   # Assert the link and location headers match up with the response RDF
#
# #   assert_equal 1, graph.query([RDF::URI(proxy_uri), RDF.type, ORE.Proxy]).count
# #   assert_equal 1, graph.query([RDF::URI(proxy_uri), ORE.proxyFor, test_folder_uri]).count
# #   assert_equal 1, graph.query([resource_map_uri, ORE.describes, test_folder_uri]).count
#
# #   # Assert the statements in the manifest.
#
# #   get ro_uri + ResearchObject::MANIFEST_PATH
# #   assert_response :ok
#
# #   manifest_graph = load_graph(@response.body)
#
# #   assert_equal 1, manifest_graph.query([RDF::URI(proxy_uri), RDF.type, ORE.Proxy]).count
# #   assert_equal 1, manifest_graph.query([RDF::URI(proxy_uri), ORE.proxyFor, test_folder_uri]).count
# #   assert_equal 1, manifest_graph.query([resource_map_uri, ORE.describes, test_folder_uri]).count
#   end

  def parse_links(headers)

    links = {}

    link_headers = headers["Link"]

    return {} if link_headers.nil?

    if link_headers
      link_headers.each do |link|
        matches = link.strip.match(/<([^>]*)>\s*;.*rel\s*=\s*"?([^;"]*)"?/)
        if matches
          links[matches[2]] ||= []
          links[matches[2]] << matches[1]
        end
      end
    end

    links
  end

end
