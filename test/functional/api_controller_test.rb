require File.dirname(__FILE__) + '/../test_helper'
require 'api_controller'
require 'xml/libxml'
require 'lib/rest'

# Re-raise errors caught by the controller.
class ApiController; def rescue_action(e) raise e end; end

class ApiControllerTest < Test::Unit::TestCase

  fixtures :workflows, :users, :content_types, :licenses

  def setup
    @controller = ApiController.new
    @request    = TestRequestWithQuery.new
    @response   = ActionController::TestResponse.new
  end

  def test_workflows

    existing_workflows = Workflow.find(:all)

    login_as(:john)

    title        = "Unique tags"
    title2       = "Unique tags again"
    license_type = "by-sa"
    content_type = "application/vnd.taverna.scufl+xml"
    description  = "A workflow description."

    content = Base64.encode64(File.read('test/fixtures/files/workflow_dilbert.xml'))

    # post a workflow

    rest_request(:post, 'workflow', "<?xml version='1.0'?>
      <workflow>
        <title>#{title}</title>
        <description>#{description}</description>
        <license-type>#{license_type}</license-type>
        <content-type>#{content_type}</content-type>
        <content>#{content}</content>
      </workflow>")

    assert_response(:success)

    extra_workflows = Workflow.find(:all) - existing_workflows

    assert_equal(extra_workflows.length, 1)

    @workflow_id = extra_workflows.first.id

    # get the workflow

    response = rest_request(:get, 'workflow', nil, "id" => @workflow_id,
        "elements" => "title,description,license-type,content-type,content")

    assert_response(:success)
  
    assert_equal(title,        response.find_first('/workflow/title').inner_xml)
    assert_equal(description,  response.find_first('/workflow/description').inner_xml)
    assert_equal(license_type, response.find_first('/workflow/license-type').inner_xml)
    assert_equal(content_type, response.find_first('/workflow/content-type').inner_xml)
    assert_equal(content,      response.find_first('/workflow/content').inner_xml)

    # it's private default, so make sure that another user can't get the
    # workflow

    setup;
    login_as(:jane)

    rest_request(:get, 'workflow', nil, "id" => @workflow_id)

    assert_response(401)
     
    # update the workflow

    setup
    login_as(:john)

    rest_request(:put, 'workflow', "<?xml version='1.0'?>
      <workflow>
        <title>#{title2}</title>
      </workflow>", "id" => @workflow_id)

    assert_response(:success)

    # get the updated workflow

    response = rest_request(:get, 'workflow', nil, "id" => @workflow_id,
        "elements" => "title,description")

    assert_response(:success)
  
    assert_equal(title2,      response.find_first('/workflow/title').inner_xml)
    assert_equal(description, response.find_first('/workflow/description').inner_xml)

    # delete the workflow

    rest_request(:delete, 'workflow', nil, "id" => @workflow_id)

    assert_response(:success)

    # try to get the deleted workflow

    rest_request(:get, 'workflow', nil, "id" => @workflow_id)

    assert_response(:not_found)
  end

  def test_packs

    existing_packs = Pack.find(:all)

    login_as(:john)

    title        = "A pack"
    title2       = "An updated pack"
    description  = "A pack description."

    # post a pack

    rest_request(:post, 'pack', "<?xml version='1.0'?>
      <pack>
        <title>#{title}</title>
        <description>#{description}</description>
        <permissions>
          <permission>
            <category>public</category>
            <privilege type='view'/>
            <privilege type='download'/>
          </permission>
        </permissions>
      </pack>")
    
    assert_response(:success)

    extra_packs = Pack.find(:all) - existing_packs

    assert_equal(extra_packs.length, 1)

    @pack_id = extra_packs.first.id

    # get the pack

    response = rest_request(:get, 'pack', nil, "id" => @pack_id,
        "elements" => "title,description")

    assert_response(:success)
  
    assert_equal(title,        response.find_first('/pack/title').inner_xml)
    assert_equal(description,  response.find_first('/pack/description').inner_xml)

    # make sure that another user can get the pack, since it's supposed to be
    # public

    setup;
    login_as(:jane)

    rest_request(:get, 'pack', nil, "id" => @pack_id)

    assert_response(:success)
     
    # update the pack

    setup
    login_as(:john)

    rest_request(:put, 'pack', "<?xml version='1.0'?>
      <pack>
        <title>#{title2}</title>
      </pack>", "id" => @pack_id)

    assert_response(:success)

    # get the updated pack

    response = rest_request(:get, 'pack', nil, "id" => @pack_id,
        "elements" => "title,description")

    assert_response(:success)
  
    assert_equal(title2,      response.find_first('/pack/title').inner_xml)
    assert_equal(description, response.find_first('/pack/description').inner_xml)

    # add an internal pack item

    existing_internal_pack_items = PackContributableEntry.find(:all)

    pack_uri     = rest_resource_uri(Pack.find(@pack_id))
    workflow_uri = rest_resource_uri(Workflow.find(1))
    comment1     = "It's an internal pack item."
    comment2     = "It's an updated internal pack item."

    rest_request(:post, 'internal-pack-item', "<?xml version='1.0'?>
      <internal-pack-item>
        <pack resource='#{pack_uri}'/>
        <item resource='#{workflow_uri}'/>
        <comment>#{comment1}</comment>
      </internal-pack-item>")

    assert_response(:success)

    extra_internal_pack_items = PackContributableEntry.find(:all) - existing_internal_pack_items

    assert_equal(extra_internal_pack_items.length, 1)

    @internal_pack_item_id = extra_internal_pack_items.first.id
    
    # get the internal pack item

    response = rest_request(:get, 'internal-pack-item', nil, "id" => @internal_pack_item_id)

    assert_response(:success)

    assert_equal(pack_uri,     response.find_first('/internal-pack-item/pack/@resource').value)
    assert_equal(workflow_uri, response.find_first('/internal-pack-item/item/*/@resource').value)
    assert_equal(comment1,     response.find_first('/internal-pack-item/comment').inner_xml)

    # update the internal pack item

    rest_request(:put, 'internal-pack-item', "<?xml version='1.0'?>
      <internal-pack-item>
        <comment>#{comment2}</comment>
      </internal-pack-item>", "id" => @internal_pack_item_id)

    assert_response(:success)

    # get the updated internal pack item

    response = rest_request(:get, 'internal-pack-item', nil, "id" => @internal_pack_item_id)

    assert_response(:success)

    assert_equal(comment2, response.find_first('/internal-pack-item/comment').inner_xml)

    # delete the internal pack item

    rest_request(:delete, 'internal-pack-item', nil, "id" => @internal_pack_item_id)

    assert_response(:success)

    # try to get the deleted internal pack item

    response = rest_request(:get, 'internal-pack-item', nil, "id" => @internal_pack_item_id)

    assert_response(:not_found)

    # add an external pack item

    existing_external_pack_items = PackRemoteEntry.find(:all)

    external_uri  = "http://example.com/"
    alternate_uri = "http://example.com/alternate"
    comment3      = "It's an external pack item."
    comment4      = "It's an updated external pack item."
    title         = "Title for the external pack item."

    rest_request(:post, 'external-pack-item', "<?xml version='1.0'?>
      <external-pack-item>
        <pack resource='#{pack_uri}'/>
        <title>#{title}</title>
        <uri>#{external_uri}</uri>
        <alternate-uri>#{alternate_uri}</alternate-uri>
        <comment>#{comment3}</comment>
      </external-pack-item>")

    assert_response(:success)

    extra_external_pack_items = PackRemoteEntry.find(:all) - existing_external_pack_items

    assert_equal(extra_external_pack_items.length, 1)

    @external_pack_item_id = extra_external_pack_items.first.id
    
    # get the external pack item

    response = rest_request(:get, 'external-pack-item', nil, "id" => @external_pack_item_id,
      "elements" => "pack,title,uri,alternate-uri,comment")

    assert_response(:success)

    assert_equal(pack_uri,      response.find_first('/external-pack-item/pack/@resource').value)
    assert_equal(external_uri,  response.find_first('/external-pack-item/uri').inner_xml)
    assert_equal(alternate_uri, response.find_first('/external-pack-item/alternate-uri').inner_xml)
    assert_equal(comment3,      response.find_first('/external-pack-item/comment').inner_xml)

    # update the external pack item

    rest_request(:put, 'external-pack-item', "<?xml version='1.0'?>
      <external-pack-item>
        <comment>#{comment4}</comment>
      </external-pack-item>", "id" => @external_pack_item_id)

    assert_response(:success)

    # get the updated external pack item

    response = rest_request(:get, 'external-pack-item', nil, "id" => @external_pack_item_id)

    assert_response(:success)

    assert_equal(comment4, response.find_first('/external-pack-item/comment').inner_xml)

    # delete the external pack item

    rest_request(:delete, 'external-pack-item', nil, "id" => @external_pack_item_id)

    assert_response(:success)

    # try to get the deleted external pack item

    response = rest_request(:get, 'external-pack-item', nil, "id" => @external_pack_item_id)

    assert_response(:not_found)

    # delete the pack

    rest_request(:delete, 'pack', nil, "id" => @pack_id)

    assert_response(:success)

    # try to get the deleted pack

    rest_request(:get, 'pack', nil, "id" => @pack_id)

    assert_response(:not_found)
  end

  private

  def rest_request(method, uri, data = nil, query = {})

    @request.query_parameters!(query) if query

    @request.env['RAW_POST_DATA'] = data if data

    # puts "Sending: #{data.inspect}"

    case method
      when :get;    get(:process_request,     { :uri => uri } )
      when :post;   post(:process_request,    { :uri => uri } )
      when :put;    put(:process_request,     { :uri => uri } )
      when :delete; delete(:process_request,  { :uri => uri } )
    end

    # puts "Response: #{LibXML::XML::Parser.string(@response.body).parse.root.to_s}"

    LibXML::XML::Parser.string(@response.body).parse
  end
end

# Custom version of the TestRequest, so that I can set the query parameters of
# a request.

class TestRequestWithQuery < ActionController::TestRequest

  def query_parameters!(hash)
    @custom_query_parameters = hash
  end


  def recycle!
    super

    if @custom_query_parameters
      self.query_parameters = @custom_query_parameters
      @custom_query_parameters = nil
    end
  end
end

