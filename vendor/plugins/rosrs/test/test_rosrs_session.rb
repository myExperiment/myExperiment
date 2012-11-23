# Test suite for ROSRS_Session
require File.dirname(__FILE__) + '/helper'


class TestROSRSSession < Test::Unit::TestCase

  # Test configuration values - may be imported later
  #
  # @@TODO: create separate module for test configuration (RODL, etc)
  #
  class Config
    def self.rosrs_api_uri; "http://sandbox.wf4ever-project.org/rodl/ROs/"; end
    def self.authorization; "b1b286f1-24cf-4a86-97b1-208513d403ee"; end
    def self.test_ro_name;  "TestSessionRO_ruby"; end
    def self.test_ro_path; test_ro_name+"/"; end
    def self.test_ro_uri;   rosrs_api_uri+test_ro_path; end
    def self.test_res1_rel; "subdir/res1.txt"; end
    def self.test_res2_rel; "subdir/res2.rdf"; end
    def self.test_res1_uri; test_ro_uri+test_res1_rel; end
    def self.test_res2_uri; test_ro_uri+test_res2_rel; end
  end

  def setup
    @rouri = nil
    @rosrs = ROSRS::Session.new(Config.rosrs_api_uri, Config.authorization)

    StringIO.class_eval do
      def readpartial(*args)
        result = read(*args)
        if result.nil?
          raise EOFError
        else
          result
        end
      end
    end
  end

  def teardown
    if @rosrs
      @rosrs.close
    end
  end

  def uri(str)
    RDF::URI(str)
  end

  def lit(str)
    RDF::Literal(str)
  end

  def stmt(triple)
    s,p,o = triple
    RDF::Statement(:subject=>s, :predicate=>p, :object=>o)
  end

  def assert_contains(triple, graph)
    assert(graph.match?(stmt(triple)), "Expected triple #{triple}")
  end

  def assert_not_contains(triple, graph)
    assert(!graph.match?(stmt(triple)), "Unexpected triple #{triple}")
  end

  def assert_includes(item, list)
    assert(list.include?(item), "Expected item #{item} in list: #{list.inspect}")
  end

  def assert_not_includes(item, list)
    assert(!list.include?(item), "Unexpected item #{item} in list: #{list.inspect}")
  end

  def create_test_research_object
    c, r = @rosrs.delete_research_object(Config.test_ro_uri)
    c,r,u,m = @rosrs.create_research_object(Config.test_ro_name,
        "Test RO for Session", "TestROSRS_Session.py", "2012-09-28")
    assert_equal(c, 201)
    @rouri = u
    [c,r,u,m]
  end

  def populate_test_research_object
    # Add plain text resource
    res1_body = %q(#{test_res1_uri}
        resource body line 2
        resource body line 3
        end
        )
    options = { :body => res1_body, :ctype => "text/plain" }
    c, r, puri, ruri = @rosrs.aggregate_internal_resource(
        @rouri, Config.test_res1_rel, options)
    assert_equal(201, c)
    assert_equal("Created", r)
    assert_equal(Config.test_res1_uri, ruri.to_s)
    @res_txt = ruri
    # Add RDF resource
    res2_body = %q(
        <rdf:RDF
          xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
          xmlns:ex="http://example.org/" >
          <ex:Resource rdf:about="http:/example.com/res/1">
            <ex:foo rdf:resource="http://example.com/res/1" />
            <ex:bar>Literal property</ex:bar>
          </ex:Resource>
        </rdf:RDF>
        )
    options = { :body => res2_body, :ctype => "application/rdf+xml" }
    c, r, puri, ruri = @rosrs.aggregate_internal_resource(
        @rouri, Config.test_res2_rel, options)
    assert_equal(201, c)
    assert_equal("Created", r)
    assert_equal(Config.test_res2_uri, ruri.to_s)
    @res_rdf = ruri
    # @@TODO Add external resource
  end

  def delete_test_research_object
    c, r = @rosrs.delete_research_object(@rouri)
    [c, r]
  end

  # ----------
  # Test cases
  # ----------

  def test_namespaces
    assert_equal(RDF::URI("http://www.openarchives.org/ore/terms/Aggregation"), RDF::ORE.Aggregation)
    assert_equal(RDF::URI("http://purl.org/wf4ever/ro#ResearchObject"), RDF::RO.ResearchObject)
    assert_equal(RDF::URI("http://www.w3.org/2000/01/rdf-schema#seeAlso"), RDF::RDFS.seeAlso)
  end

  def test_create_serialize_graph
    b = %q(
        <rdf:RDF
          xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
          xmlns:ex="http://example.org/" >
          <ex:Resource rdf:about="http:/example.com/res/1">
            <ex:foo rdf:resource="http://example.com/res/1" />
            <ex:bar>Literal property</ex:bar>
          </ex:Resource>
        </rdf:RDF>
        )
    g  = ROSRS::RDFGraph.new(:data => b)
    b1 = g.serialize(format=:ntriples)
    r1 = %r{<http:/example\.com/res/1> <http://example\.org/foo> <http://example\.com/res/1> \.}
    r2 = %r{<http:/example\.com/res/1> <http://example\.org/bar> "Literal property" \.}
    [r1,r2].each do |r|
      assert(b1 =~ r, "Not matched: #{r}")
    end
  end

  def test_query_graph
    b = %q(
        <rdf:RDF
          xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
          xmlns:ex="http://example.org/" >
          <ex:Resource rdf:about="http:/example.com/res/1">
            <ex:foo rdf:resource="http://example.com/res/1" />
            <ex:bar>Literal property</ex:bar>
          </ex:Resource>
        </rdf:RDF>
        )
    g  = ROSRS::RDFGraph.new(:data => b)
    stmts = []
    g.query([nil, nil, nil]) { |s| stmts << s }
    s1 = stmt([uri("http:/example.com/res/1"),uri("http://example.org/foo"),uri("http://example.com/res/1")])
    s2 = stmt([uri("http:/example.com/res/1"),uri("http://example.org/bar"),lit("Literal property")])
    assert_includes(s1, stmts)
    assert_includes(s2, stmts)
    stmts = []
    g.query(:object => uri("http://example.com/res/1")) { |s| stmts << s }
    assert_includes(s1, stmts)
    assert_not_includes(s2, stmts)
  end

  def test_http_simple_get
    c,r,u,m = create_test_research_object
    assert_equal(201, c)
    c,r,h,b = @rosrs.do_request("GET", @rouri,
      {:accept => "application/rdf+xml"})
    assert_equal(303, c)
    assert_equal("See Other", r)
    assert_equal("application/rdf+xml", h["content-type"])
    assert_equal("", b)
    c,r = delete_test_research_object
  end

  def test_http_redirected_get
    c,r,u,m = create_test_research_object
    assert_equal(201, c)
    c,r,h,u,b = @rosrs.do_request_follow_redirect("GET", @rouri,
        {:accept => "application/rdf+xml"})
    assert_equal(200, c)
    assert_equal("OK", r)
    assert_equal("application/rdf+xml", h["content-type"])
    assert_equal(Config.test_ro_uri+".ro/manifest.rdf", u.to_s)
    #assert_match(???, b)
    c,r = delete_test_research_object
  end

  def test_create_research_object
    c,r,u,m = create_test_research_object
    assert_equal(201, c)
    assert_equal("Created", r)
    assert_equal(Config.test_ro_uri, u)
    s = stmt([uri(Config.test_ro_uri), RDF.type, RDF::RO.ResearchObject])
    assert_contains(s, m)
    c,r = delete_test_research_object
    assert_equal(204, c)
    assert_equal("No Content", r)
  end

  def test_get_manifest
    # [manifesturi, manifest] = get_ro_manifest(rouri)
    c,r,u,m = create_test_research_object
    assert_equal(201, c)
    # Get manifest
    manifesturi, manifest = @rosrs.get_manifest(u)
    assert_equal(@rouri.to_s+".ro/manifest.rdf", manifesturi.to_s)
    # Check manifest RDF graph
    assert_contains([uri(@rouri), RDF.type, RDF::RO.ResearchObject], manifest)
    assert_contains([uri(@rouri), RDF::DC.creator, nil], manifest)
    assert_contains([uri(@rouri), RDF::DC.created, nil], manifest)
    assert_contains([uri(@rouri), RDF::ORE.isDescribedBy, uri(manifesturi)], manifest)
  end

  def test_aggregate_internal_resource
    c,r,u,m = create_test_research_object
    assert_equal(201, c)
    body    = "test_aggregate_internal_resource resource body\n"
    options = { :body => body, :ctype => "text/plain" }
    c, r, puri, ruri = @rosrs.aggregate_internal_resource(
        @rouri, "test_aggregate_internal_resource", options)
    assert_equal(201, c)
    assert_equal("Created", r)
    puri_exp = Config.test_ro_uri+".ro/proxies/"
    puri_act = puri.to_s.slice(0...puri_exp.length)
    assert_equal(puri_exp, puri_act)
    assert_equal(Config.test_ro_uri+"test_aggregate_internal_resource", ruri.to_s)
    c,r = delete_test_research_object
  end

  def test_create_annotation_body
    c,r,u,m = create_test_research_object
    assert_equal(201, c)
    b = %q(
        <rdf:RDF
          xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
          xmlns:ex="http://example.org" >
          <ex:Resource rdf:about="http:/example.com/res/1">
            <ex:foo rdf:resource="http://example..com/res/1" />
            <ex:bar>Literal property</ex:bar>
          </ex:Resource>
        </rdf:RDF>
        )
    g = ROSRS::RDFGraph.new(:data => b)
    # Create an annotation body from a supplied annnotation graph.
    # Params:  (rouri, anngr)
    # Returns: (status, reason, bodyuri)
    c,r,u = @rosrs.create_annotation_body(@rouri, g)
    assert_equal(201, c)
    assert_equal("Created", r)
    assert_match(%r(http://sandbox.wf4ever-project.org/rodl/ROs/TestSessionRO_ruby/), u.to_s)
    #assert_equal(nil, u)
    c,r = delete_test_research_object
  end

  def test_create_annotation_stub
    # [code, reason, stuburi] = create_annotation_stub(rouri, resuri, bodyuri)
    c,r,u,m = create_test_research_object
    assert_equal(201, c)
    c,r,u = @rosrs.create_annotation_stub(@rouri,
        "http://example.org/resource", "http://example.org/body")
    assert_equal(201, c)
    assert_equal("Created", r)
    assert_match(%r(http://sandbox.wf4ever-project.org/rodl/ROs/TestSessionRO_ruby/\.ro/), u.to_s)
    c,r = delete_test_research_object
  end

  def test_create_internal_annotation
    # [code, reason, annuri, bodyuri] = create_internal_annotation(rouri, resuri, anngr)
    c,r,u,m = create_test_research_object
    assert_equal(201, c)
    populate_test_research_object
    # Create internal annotation on @res_txt
    annbody1 = %Q(<?xml version="1.0" encoding="UTF-8"?>
      <rdf:RDF
         xmlns:dct="http://purl.org/dc/terms/"
         xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
         xml:base="#@rouri"
      >
        <rdf:Description rdf:about="#@res_txt">
        <dct:title>Title 1</dct:title>
        <rdfs:seeAlso rdf:resource="http://example.org/test1" />
        </rdf:Description>
      </rdf:RDF>
      )
    agraph1 = ROSRS::RDFGraph.new(:data => annbody1, :format => :xml)
    c,r,annuri,bodyuri1 = @rosrs.create_internal_annotation(
      @rouri, @res_txt, agraph1)
    assert_equal(201, c)
    assert_equal("Created", r)
    # Retrieve annotation URIs
    auris1 = @rosrs.get_annotation_stub_uris(@rouri, @res_txt)
    assert_includes(uri(annuri), auris1)
    buris1 = @rosrs.get_annotation_body_uris(@rouri, @res_txt)
    assert_includes(uri(bodyuri1), buris1)
    # Retrieve annotation
    c,r,auri1,agr1a = @rosrs.get_annotation_body(annuri)
    assert_equal(200, c)
    assert_equal("OK", r)
    # The following test fails, due to a temp[orary redirect from the annotation
    # body URI in the stub to the actual URI used to retrieve the body:
    # assert_includes(auri1, buris1)
    s1a = [uri(@res_txt), RDF::DC.title, lit("Title 1")]
    s1b = [uri(@res_txt), RDF::RDFS.seeAlso,  uri("http://example.org/test1")]
    assert_contains(s1a,agr1a)
    assert_contains(s1b,agr1a)
    # Retrieve merged annotations
    agr1b = @rosrs.get_annotation_graph(@rouri, @res_txt)
    assert_contains(s1a,agr1b)
    assert_contains(s1b,agr1b)
    # Update internal annotation
    annbody2 = %Q(<?xml version="1.0" encoding="UTF-8"?>
      <rdf:RDF
        xmlns:dct="http://purl.org/dc/terms/"
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
        xml:base="#@rouri"
      >
        <rdf:Description rdf:about="#@res_txt">
        <dct:title>Title 2</dct:title>
        <rdfs:seeAlso rdf:resource="http://example.org/test2" />
        </rdf:Description>
      </rdf:RDF>
      )
    agraph2 = ROSRS::RDFGraph.new(:data => annbody2, :format => :xml)
    c,r,bodyuri2 = @rosrs.update_internal_annotation(
      @rouri, annuri, @res_txt, agraph2)
    assert_equal(c, 200)
    assert_equal(r, "OK")
    # Retrieve annotation URIs
    auris2 = @rosrs.get_annotation_stub_uris(@rouri, @res_txt)
    assert_includes(uri(annuri), auris2)
    buris2 = @rosrs.get_annotation_body_uris(@rouri, @res_txt)
    assert_includes(uri(bodyuri2), buris2)
    # Retrieve annotation
    c,r,auri2,agr2a = @rosrs.get_annotation_body(annuri)
    assert_equal(c, 200)
    assert_equal(r, "OK")
    s2a = [uri(@res_txt), RDF::DC.title, lit("Title 2")]
    s2b = [uri(@res_txt), RDF::RDFS.seeAlso,  uri("http://example.org/test2")]
    assert_not_contains(s1a,agr2a)
    assert_not_contains(s1b,agr2a)
    assert_contains(s2a,agr2a)
    assert_contains(s2b,agr2a)
    # Retrieve merged annotations
    agr2b = @rosrs.get_annotation_graph(@rouri, @res_txt)
    assert_not_contains(s1a,agr2b)
    assert_not_contains(s1b,agr2b)
    assert_contains(s2a,agr2b)
    assert_contains(s2b,agr2b)
    # Clean up
    c,r = delete_test_research_object
  end

  def test_create_external_annotation
    c,r,u,m = create_test_research_object
    assert_equal(201, c)
    populate_test_research_object

    # Create external annotation on @res_txt
    c,r,annuri,bodyuri1 = @rosrs.create_external_annotation(@rouri, @res_txt, "http://www.example.com/something")
    assert_equal(201, c)
    assert_equal("Created", r)

    # Retrieve annotation URIs
    auris1 = @rosrs.get_annotation_stub_uris(@rouri, @res_txt)
    assert_includes(uri(annuri), auris1)
    buris1 = @rosrs.get_annotation_body_uris(@rouri, @res_txt)
    assert_includes(uri(bodyuri1), buris1)

    # Update external annotation
    c,r,bodyuri2 = @rosrs.update_external_annotation(@rouri, annuri, @res_txt, "http://www.example.com/other")
    assert_equal(c, 200)
    assert_equal(r, "OK")

    # Retrieve annotation URIs
    auris2 = @rosrs.get_annotation_stub_uris(@rouri, @res_txt)
    assert_includes(uri(annuri), auris2)
    buris2 = @rosrs.get_annotation_body_uris(@rouri, @res_txt)
    assert_includes(uri(bodyuri2), buris2)

    # Remove annotation
    code, reason = @rosrs.remove_annotation(annuri)
    assert_equal(code, 204)

    # Clean up
    c,r = delete_test_research_object
  end


 end
