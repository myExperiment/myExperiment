require File.dirname(__FILE__) + '/../test_helper'
require 'api_controller'
require 'xml/libxml'
require 'rest'

class ApiControllerTest < ActionController::TestCase

  include Rails.application.routes.url_helpers
  Rails.application.routes.default_url_options[:host] = 'test.host'

  def setup
    @controller = ApiController.new
    @response   = ActionController::TestResponse.new
  end

  fixtures :workflows, :users, :content_types, :licenses, :ontologies, :predicates, :packs, :tags, :taggings

  def test_workflows

    existing_workflows = Workflow.find(:all)
    existing_activities = Activity.all

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
    extra_activities = Activity.find(:all). - existing_activities

    assert_equal(1, extra_workflows.length)
    assert_equal(2, extra_activities.length)

    new_activity = (extra_activities - existing_activities)[1]

    assert_equal("John Smith", new_activity.subject_label);
    assert_equal("create", new_activity.action);
    assert_equal(title, new_activity.objekt_label);

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

    setup
    login_as(:jane)

    rest_request(:get, 'workflow', nil, "id" => @workflow_id)

    assert_response(:unauthorized)
     
    # update the workflow

    setup
    login_as(:john)

    existing_activities = Activity.all

    rest_request(:put, 'workflow', "<?xml version='1.0'?>
      <workflow>
        <title>#{title2}</title>
      </workflow>", "id" => @workflow_id)

    assert_response(:success)

    extra_activities = Activity.find(:all). - existing_activities
    assert_equal(1, extra_activities.length)
    
    new_activity = (extra_activities - existing_activities).first

    assert_equal("John Smith", new_activity.subject_label);
    assert_equal("edit", new_activity.action);
    assert_equal(title2, new_activity.objekt_label);

    # get the updated workflow

    response = rest_request(:get, 'workflow', nil, "id" => @workflow_id,
        "elements" => "title,description")

    assert_response(:success)
  
    assert_equal(title2,      response.find_first('/workflow/title').inner_xml)
    assert_equal(description, response.find_first('/workflow/description').inner_xml)

    # upload a new version of the workflow

    content2 = Base64.encode64(File.read('test/fixtures/files/workflow_xkcd.t2flow'))

    # post a new version of the workflow

    existing_activities = Activity.all

    rest_request(:post, 'workflow', "<?xml version='1.0'?>
      <workflow>
        <type>Taverna 2</type>
        <content>#{content2}</content>
      </workflow>", "id" => @workflow_id)

    assert_response(:success)

    extra_activities = Activity.find(:all). - existing_activities
    assert_equal(1, extra_activities.length)

    new_activity = (extra_activities - existing_activities).first

    assert_equal("John Smith", new_activity.subject_label);
    assert_equal("create", new_activity.action);
    assert_equal("Fetch today's xkcd comic", new_activity.objekt_label);

    workflow = Workflow.find(@workflow_id)

    assert_equal(2, workflow.versions.length)

    # get different versions of the workflow

    response = rest_request(:get, 'workflow', nil, "id" => @workflow_id, "version" => "1",
        "elements" => "title,type,content-type,content,components")

    assert_response(:success)
  
    assert_equal(title2, response.find_first('/workflow/title').inner_xml)
    assert_equal("Taverna 1",  response.find_first('/workflow/type').inner_xml)
    assert_equal("application/vnd.taverna.scufl+xml", response.find_first('/workflow/content-type').inner_xml)
    assert_equal(1815, Base64.decode64(response.find_first('/workflow/content').inner_xml).length)

    response = rest_request(:get, 'workflow', nil, "id" => @workflow_id, "version" => "2",
        "elements" => "title,type,content-type,content,components")

    assert_equal("Fetch today's xkcd comic", response.find_first('/workflow/title').inner_xml)
    assert_equal("Taverna 2",  response.find_first('/workflow/type').inner_xml)
    assert_equal("application/vnd.taverna.t2flow+xml", response.find_first('/workflow/content-type').inner_xml)
    assert_equal(30218, Base64.decode64(response.find_first('/workflow/content').inner_xml).length)

    # edit a particular version of a workflow

    existing_activities = Activity.all

    rest_request(:put, 'workflow', "<?xml version='1.0'?>
      <workflow>
        <title>Oranges</title>
      </workflow>", "id" => @workflow_id, "version" => "1")

    assert_response(:success)

    extra_activities = Activity.find(:all). - existing_activities
    assert_equal(1, extra_activities.length)
    
    new_activity = (extra_activities - existing_activities).first

    assert_equal("John Smith", new_activity.subject_label);
    assert_equal("edit",       new_activity.action);
    assert_equal("1",          new_activity.extra);
    assert_equal("Oranges",    new_activity.objekt_label);

    # Verify that only version 1 was changed

    response = rest_request(:get, 'workflow', nil, "id" => @workflow_id, "version" => "1",
        "elements" => "title")

    assert_response(:success)
  
    assert_equal("Oranges", response.find_first('/workflow/title').inner_xml)

    response = rest_request(:get, 'workflow', nil, "id" => @workflow_id, "version" => "2",
        "elements" => "title")

    assert_equal("Fetch today's xkcd comic", response.find_first('/workflow/title').inner_xml)

    # delete the workflow

    rest_request(:delete, 'workflow', nil, "id" => @workflow_id)

    assert_response(:success)

    # try to get the deleted workflow

    rest_request(:get, 'workflow', nil, "id" => @workflow_id)

    assert_response(:not_found)
  end

  def test_files

    existing_files = Blob.find(:all)

    login_as(:john)

    title        = "Test file title"
    title2       = "Updated test file title"
    title3       = "Updated test file title for versions"
    license_type = "by-sa"
    content_type = "text/plain"
    description  = "A description of the test file."

    content  = Base64.encode64("This is the content of this test file.")
    content2 = Base64.encode64("This is the content of this test file, version 2.")

    # post a file

    existing_activities = Activity.all

    rest_request(:post, 'file', "<?xml version='1.0'?>
      <file>
        <title>#{title}</title>
        <description>#{description}</description>
        <license-type>#{license_type}</license-type>
        <filename>test.txt</filename>
        <content-type>#{content_type}</content-type>
        <content>#{content}</content>
      </file>")

    assert_response(:success)

    new_activities = Activity.all - existing_activities

    assert_equal(2, new_activities.length)

    assert_equal("John Smith", new_activities[1].subject.name)
    assert_equal("create",     new_activities[1].action)
    assert_equal(title,        new_activities[1].objekt.title)

    extra_files = Blob.find(:all) - existing_files

    assert_equal(extra_files.length, 1)

    file = extra_files.first

    assert_equal(file.versions.length, 1)
    assert_equal(file.versions.first.version, 1)

    # get the file

    response = rest_request(:get, 'file', nil, "id" => file.id,
        "elements" => "title,description,license-type,content-type,content")

    assert_response(:success)

    assert_equal(title,        response.find_first('/file/title').inner_xml)
    assert_equal(description,  response.find_first('/file/description').inner_xml)
    assert_equal(license_type, response.find_first('/file/license-type').inner_xml)
    assert_equal(content_type, response.find_first('/file/content-type').inner_xml)
    assert_equal(content,      response.find_first('/file/content').inner_xml)

    # it's private default, so make sure that another user can't get the
    # file

    setup
    login_as(:jane)

    rest_request(:get, 'file', nil, "id" => file.id)

    assert_response(:unauthorized)
     
    # update the file

    setup
    login_as(:john)

    existing_activities = Activity.all

    rest_request(:put, 'file', "<?xml version='1.0'?>
      <file>
        <title>#{title2}</title>
      </file>", "id" => file.id)

    assert_response(:success)

    new_activities = Activity.all - existing_activities

    assert_equal(1, new_activities.length)
    assert_equal("John Smith", new_activities.first.subject.name)
    assert_equal("edit",       new_activities.first.action)
    assert_equal(title2,       new_activities.first.objekt.title)

    # get the updated file

    response = rest_request(:get, 'file', nil, "id" => file.id,
        "elements" => "title,description")

    assert_response(:success)
  
    assert_equal(title2,      response.find_first('/file/title').inner_xml)
    assert_equal(description, response.find_first('/file/description').inner_xml)

    # add a new version of the file

    existing_activities = Activity.all

    rest_request(:post, 'file', "<?xml version='1.0'?>
      <file>
        <title>#{title2}</title>
        <description>#{description}</description>
        <license-type>#{license_type}</license-type>
        <content-type>#{content_type}</content-type>
        <content>#{content2}</content>
      </file>", "id" => file.id)

    assert_response(:success)

    new_activities = Activity.all - existing_activities

    assert_equal(1, new_activities.length)
    assert_equal("John Smith",     new_activities.first.subject.name)
    assert_equal("create",         new_activities.first.action)
    assert_equal(title2,           new_activities.first.objekt.title)

    file.reload

    assert_equal(2, file.versions.length)

    # update the first version of the file

    existing_activities = Activity.all

    rest_request(:put, 'file', "<?xml version='1.0'?>
      <file>
        <title>#{title3}</title>
      </file>", "id" => file.id, "version" => 1)

    assert_response(:success)

    new_activities = Activity.all - existing_activities

    assert_equal(1, new_activities.length)
    assert_equal("John Smith",   new_activities.first.subject.name)
    assert_equal("edit",         new_activities.first.action)
    assert_equal(title3,         new_activities.first.objekt.title)

    file.reload
    assert_equal(title3, file.find_version(1).title);
    assert_equal(title2, file.find_version(2).title);
    assert_equal(title2, file.title);

    # get each version of the file

    response = rest_request(:get, 'file', nil, "id" => file.id, "version" => "1",
        "elements" => "title")

    assert_response(:success)
  
    assert_equal(title3, response.find_first('/file/title').inner_xml)

    response = rest_request(:get, 'file', nil, "id" => file.id, "version" => "2",
        "elements" => "title")

    assert_response(:success)
  
    assert_equal(title2, response.find_first('/file/title').inner_xml)

    # delete the file

    rest_request(:delete, 'file', nil, "id" => file.id)

    assert_response(:success)

    # try to get the deleted file

    rest_request(:get, 'file', nil, "id" => file.id)

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

  def test_comments

    login_as(:john)

    # post a workflow to test with

    content = Base64.encode64(File.read('test/fixtures/files/workflow_dilbert.xml'))

    existing_workflows = Workflow.find(:all)

    rest_request(:post, 'workflow', "<?xml version='1.0'?>
      <workflow>
        <title>Unique tags</title>
        <description>A workflow description.</description>
        <license-type>by-sa</license-type>
        <content-type>application/vnd.taverna.scufl+xml</content-type>
        <content>#{content}</content>
      </workflow>")

    assert_response(:success)

    extra_workflows = Workflow.find(:all) - existing_workflows

    assert_equal(extra_workflows.length, 1)

    workflow = extra_workflows.first
    workflow_url = rest_resource_uri(workflow)

    # post a comment

    comment_text  = "a test comment"
    comment_text2 = "an updated test comment"

    existing_comments = Comment.find(:all)

    existing_activities = Activity.all

    rest_request(:post, 'comment', "<?xml version='1.0'?>
      <comment>
        <comment>#{comment_text}</comment>
        <subject resource='#{workflow_url}'/>
      </comment>")

    assert_response(:success)

    new_activities = Activity.all - existing_activities

    assert_equal(1, new_activities.length)
    assert_equal("John Smith",  new_activities.first.subject.name)
    assert_equal("create",      new_activities.first.action)
    assert_equal("Unique tags", new_activities.first.objekt.commentable.title)

    extra_comments = Comment.find(:all) - existing_comments 
    
    assert_equal(extra_comments.length, 1)

    comment = extra_comments.first

    # update the comment (which should fail)

    rest_request(:put, 'comment', "<?xml version='1.0'?>
      <comment>
        <comment>#{comment_text2}</comment>
      </comment>", "id" => comment.id)

    assert_response(:unauthorized)
    
    # delete the comment

    rest_request(:delete, 'comment', nil, "id" => comment.id)

    assert_response(:success)

    # try to get the deleted comment

    rest_request(:get, 'comment', nil, "id" => comment.id)

    assert_response(:not_found)
  end

  def test_ratings

    login_as(:john)

    # post a workflow to test with

    content = Base64.encode64(File.read('test/fixtures/files/workflow_dilbert.xml'))

    existing_workflows = Workflow.find(:all)

    rest_request(:post, 'workflow', "<?xml version='1.0'?>
      <workflow>
        <title>Unique tags</title>
        <description>A workflow description.</description>
        <license-type>by-sa</license-type>
        <content-type>application/vnd.taverna.scufl+xml</content-type>
        <content>#{content}</content>
      </workflow>")

    assert_response(:success)

    extra_workflows = Workflow.find(:all) - existing_workflows

    assert_equal(extra_workflows.length, 1)

    workflow = extra_workflows.first
    workflow_url = rest_resource_uri(workflow)

    # post a rating

    existing_ratings = Rating.find(:all)

    existing_activities = Activity.all

    rest_request(:post, 'rating', "<?xml version='1.0'?>
      <rating>
        <rating>4</rating>
        <subject resource='#{workflow_url}'/>
      </rating>")

    assert_response(:success)

    new_activities = Activity.all - existing_activities

    assert_equal(1, new_activities.length)
    assert_equal("John Smith", new_activities.first.subject.name)
    assert_equal("create", new_activities.first.action)
    assert_equal("Unique tags", new_activities.first.objekt.rateable.title)
    assert_equal("Unique tags", new_activities.first.auth.title)

    extra_ratings = Rating.find(:all) - existing_ratings 
    
    assert_equal(extra_ratings.length, 1)

    rating = extra_ratings.first

    assert_equal(rating.user, users(:john));
    assert_equal(rating.rateable, workflow);
    assert_equal(rating.rating, 4);

    # update the rating

    rest_request(:put, 'rating', "<?xml version='1.0'?>
      <rating>
        <rating>3</rating>
      </rating>", "id" => rating.id)

    assert_response(:success)
    
    rating.reload

    assert_equal(3, rating.rating);

    # delete the rating

    rest_request(:delete, 'rating', nil, "id" => rating.id)

    assert_response(:success)

    # try to get the deleted rating

    rest_request(:get, 'rating', nil, "id" => rating.id)

    assert_response(:not_found)
  end

  def test_favourites

    login_as(:john)

    # post a workflow to test with

    content = Base64.encode64(File.read('test/fixtures/files/workflow_dilbert.xml'))

    existing_workflows = Workflow.find(:all)

    rest_request(:post, 'workflow', "<?xml version='1.0'?>
      <workflow>
        <title>Unique tags</title>
        <description>A workflow description.</description>
        <license-type>by-sa</license-type>
        <content-type>application/vnd.taverna.scufl+xml</content-type>
        <content>#{content}</content>
      </workflow>")

    assert_response(:success)

    extra_workflows = Workflow.find(:all) - existing_workflows

    assert_equal(extra_workflows.length, 1)

    workflow = extra_workflows.first
    workflow_url = rest_resource_uri(workflow)

    # post a favourite

    existing_favourites = Bookmark.find(:all)

    existing_activities = Activity.all

    rest_request(:post, 'favourite', "<?xml version='1.0'?>
      <favourite>
        <object resource='#{workflow_url}'/>
      </favourite>")

    assert_response(:success)

    new_activities = Activity.all - existing_activities

    assert_equal(1, new_activities.length)
    assert_equal("John Smith",  new_activities.first.subject.name)
    assert_equal("create",      new_activities.first.action)
    assert_equal("Unique tags", new_activities.first.objekt.bookmarkable.title)

    extra_favourites = Bookmark.find(:all) - existing_favourites 
    
    assert_equal(extra_favourites.length, 1)

    favourite = extra_favourites.first

    # delete the favourite

    rest_request(:delete, 'favourite', nil, "id" => favourite.id)

    assert_response(:success)

    # try to get the deleted favourite

    rest_request(:get, 'favourite', nil, "id" => favourite.id)

    assert_response(:not_found)
  end

  def test_taggings

    login_as(:john)

    # post a workflow to test with

    content = Base64.encode64(File.read('test/fixtures/files/workflow_dilbert.xml'))

    existing_workflows = Workflow.find(:all)

    rest_request(:post, 'workflow', "<?xml version='1.0'?>
      <workflow>
        <title>Unique tags</title>
        <description>A workflow description.</description>
        <license-type>by-sa</license-type>
        <content-type>application/vnd.taverna.scufl+xml</content-type>
        <content>#{content}</content>
      </workflow>")

    assert_response(:success)

    extra_workflows = Workflow.find(:all) - existing_workflows

    assert_equal(extra_workflows.length, 1)

    workflow = extra_workflows.first
    workflow_url = rest_resource_uri(workflow)

    # post a tagging

    existing_taggings = Tagging.find(:all)

    existing_activities = Activity.all

    rest_request(:post, 'tagging', "<?xml version='1.0'?>
      <tagging>
        <subject resource='#{workflow_url}'/>
        <label>my test tag</label>
      </tagging>")

    assert_response(:success)

    new_activities = Activity.all - existing_activities

    assert_equal(1, new_activities.length)
    assert_equal("John Smith", new_activities.first.subject.name)
    assert_equal("create", new_activities.first.action)
    assert_equal("my test tag", new_activities.first.objekt.tag.name)

    extra_taggings = Tagging.find(:all) - existing_taggings 
    
    assert_equal(extra_taggings.length, 1)

    tagging = extra_taggings.first

    assert_equal(tagging.user, users(:john));
    assert_equal(tagging.taggable, workflow);
    assert_equal(tagging.label, 'my test tag');

    # update the tagging (which should fail)

    rest_request(:put, 'tagging', "<?xml version='1.0'?>
      <tagging>
        <label>fail</label>
      </tagging>", "id" => tagging.id)

    assert_response(400)
    
    # delete the tagging

    rest_request(:delete, 'tagging', nil, "id" => tagging.id)

    assert_response(:success)

    # try to get the deleted tagging

    rest_request(:get, 'tagging', nil, "id" => tagging.id)

    assert_response(:not_found)
  end

  def test_ontologies

    existing_ontologies = Ontology.find(:all)

    login_as(:john)

    title       = "Test ontology title"
    title2      = "Updated test ontology title"
    uri         = "http://example.com/ontology"
    prefix      = "test prefix"
    description = "A description of the ontology."

    # post an ontology

    rest_request(:post, 'ontology', "<?xml version='1.0'?>
      <ontology>
        <title>#{title}</title>
        <description>#{description}</description>
        <uri>#{uri}</uri>
        <prefix>#{prefix}</prefix>
      </ontology>")

    assert_response(:success)

    extra_ontologies = Ontology.find(:all) - existing_ontologies

    assert_equal(extra_ontologies.length, 1)

    ontology = extra_ontologies.first

    # get the ontology

    response = rest_request(:get, 'ontology', nil, "id" => ontology.id,
        "elements" => "title,description,uri,prefix")

    assert_response(:success)

    assert_equal(title,       response.find_first('/ontology/title').inner_xml)
    assert_equal(description, response.find_first('/ontology/description').inner_xml)
    assert_equal(uri,         response.find_first('/ontology/uri').inner_xml)
    assert_equal(prefix,      response.find_first('/ontology/prefix').inner_xml)

    # update the ontology

    rest_request(:put, 'ontology', "<?xml version='1.0'?>
      <ontology>
        <title>#{title2}</title>
      </ontology>", "id" => ontology.id)

    assert_response(:success)

    # get the updated ontology

    response = rest_request(:get, 'ontology', nil, "id" => ontology.id,
        "elements" => "title,description")

    assert_response(:success)
  
    assert_equal(title2,      response.find_first('/ontology/title').inner_xml)
    assert_equal(description, response.find_first('/ontology/description').inner_xml)

    # delete the ontology

    rest_request(:delete, 'ontology', nil, "id" => ontology.id)

    assert_response(:success)

    # try to get the deleted ontology

    rest_request(:get, 'ontology', nil, "id" => ontology.id)

    assert_response(:not_found)
  end

  def test_predicates

    existing_predicates = Predicate.find(:all)

    login_as(:john)

    title            = "Test predicate title"
    title2           = "Updated test predicate title"
    ontology         = ontologies(:test_ontology_1)
    ontology_url     = rest_resource_uri(ontology)
    phrase           = "test phrase"
    description      = "A description of the predicate."
    description_html = "<p>A description of the predicate.</p>"
    equivalent_to    = "test equivalent_to"

    # post a predicate

    rest_request(:post, 'predicate', "<?xml version='1.0'?>
      <predicate>
        <title>#{title}</title>
        <ontology resource='#{ontology_url}'/>
        <phrase>#{phrase}</phrase>
        <description>#{description}</description>
        <equivalent-to>#{equivalent_to}</equivalent-to>
      </predicate>")

    assert_response(:success)

    extra_predicates = Predicate.find(:all) - existing_predicates

    assert_equal(extra_predicates.length, 1)

    predicate = extra_predicates.first

    # get the predicate

    response = rest_request(:get, 'predicate', nil, "id" => predicate.id,
        "elements" => "title,description,phrase,equivalent-to")

    assert_response(:success)

    assert_equal(title,         response.find_first('/predicate/title').inner_xml)
    assert_equal(description,   response.find_first('/predicate/description').inner_xml)
    assert_equal(phrase,        response.find_first('/predicate/phrase').inner_xml)
    assert_equal(equivalent_to, response.find_first('/predicate/equivalent-to').inner_xml)

    # update the predicate

    rest_request(:put, 'predicate', "<?xml version='1.0'?>
      <predicate>
        <title>#{title2}</title>
      </predicate>", "id" => predicate.id)

    assert_response(:success)

    # get the updated predicate

    response = rest_request(:get, 'predicate', nil, "id" => predicate.id,
        "elements" => "title,description")

    assert_response(:success)
  
    assert_equal(title2,      response.find_first('/predicate/title').inner_xml)
    assert_equal(description, response.find_first('/predicate/description').inner_xml)

    # delete the predicate

    rest_request(:delete, 'predicate', nil, "id" => predicate.id)

    assert_response(:success)

    # try to get the deleted predicate

    rest_request(:get, 'predicate', nil, "id" => predicate.id)

    assert_response(:not_found)
  end

  def test_relationships

    existing_relationships = Relationship.find(:all)

    login_as(:john)

    subject_url   = rest_resource_uri(workflows(:workflow_branch_choice))
    predicate_url = rest_resource_uri(predicates(:test_predicate_1))
    objekt_url    = rest_resource_uri(workflows(:workflow_dilbert))
    context_url   = rest_resource_uri(packs(:pack_1))

    # post a relationship

    rest_request(:post, 'relationship', "<?xml version='1.0'?>
      <relationship>
        <subject resource='#{subject_url}'/>
        <predicate resource='#{predicate_url}'/>
        <object resource='#{objekt_url}'/>
        <context resource='#{context_url}'/>
      </relationship>")

    assert_response(:success)

    extra_relationships = Relationship.find(:all) - existing_relationships

    assert_equal(extra_relationships.length, 1)

    relationship = extra_relationships.first

    # get the relationship

    response = rest_request(:get, 'relationship', nil, "id" => relationship.id,
        "elements" => "user,subject,predicate,object,context")

    assert_response(:success)

    assert_equal(subject_url,   response.find_first('/relationship/subject/*/@resource').value)
    assert_equal(predicate_url, response.find_first('/relationship/predicate/@resource').value)
    assert_equal(objekt_url,    response.find_first('/relationship/object/*/@resource').value)
    assert_equal(context_url,   response.find_first('/relationship/context/*/@resource').value)

    # delete the relationship

    rest_request(:delete, 'relationship', nil, "id" => relationship.id)

    assert_response(:success)

    # try to get the deleted relationship

    rest_request(:get, 'relationship', nil, "id" => relationship.id)

    assert_response(:not_found)
  end

  # Group Policies

  test "can create file with group policy" do
    login_as(:john)

    group_policy = policies(:group_policy)

    # post a file
    assert_difference('Blob.count', 1) do
      rest_request(:post, 'file', "<?xml version='1.0'?>
      <file>
        <title>A File With a Group Policy</title>
        <description>Description</description>
        <license-type>by-sa</license-type>
        <filename>test.txt</filename>
        <content-type>text/plain</content-type>
        <content>#{Base64.encode64("This is the content of this test file.")}</content>
        <permissions>
          <group-policy-id>#{group_policy.id}</group-policy-id>
        </permissions>
      </file>")
    end

    assert_response(:success)
  end

  test "non-existant group policy doesn't error out" do
    login_as(:john)

    fake_id = Policy.last.id + 100000

    # post a file
    rest_request(:post, 'file', "<?xml version='1.0'?>
    <file>
      <title>A File With a Group Policy</title>
      <description>Description</description>
      <license-type>by-sa</license-type>
      <filename>test.txt</filename>
      <content-type>text/plain</content-type>
      <content>#{Base64.encode64("This is the content of this test file.")}</content>
      <permissions>
        <group-policy-id>#{fake_id}</group-policy-id>
      </permissions>
    </file>")
  end

  test "non-member using a group policy doesn't error out" do
    login_as(:jane)

    group_policy = policies(:group_policy)

    # post a file
    rest_request(:post, 'file', "<?xml version='1.0'?>
    <file>
      <title>A File With a Group Policy</title>
      <description>Description</description>
      <license-type>by-sa</license-type>
      <filename>test.txt</filename>
      <content-type>text/plain</content-type>
      <content>#{Base64.encode64("This is the content of this test file.")}</content>
      <permissions>
        <group-policy-id>#{group_policy.id}</group-policy-id>
      </permissions>
    </file>")
  end

  # Components

  test "can create components" do
    login_as(:john)

    # Check empty
    TripleStore.instance.repo = {}
    resp = rest_request(:get, 'components')
    assert_response(:success)
    assert_equal 0, resp.find('//workflow').size

    # Upload a component workflow
    license_type = "by-sa"
    content_type = "application/vnd.taverna.t2flow+xml"
    content = Base64.encode64(File.read('test/fixtures/files/image_to_tiff_migration.t2flow'))
    family = packs(:component_family)
    workflow_resp = rest_request(:post, 'component', "<?xml version='1.0'?>
      <workflow>
        <title>Test Component</title>
        <description>123</description>
        <component-family>#{polymorphic_url(family)}</component-family>
        <license-type>#{license_type}</license-type>
        <content-type>#{content_type}</content-type>
        <content>#{content}</content>
      </workflow>")

    assert_response(:success)

    # Get the newly created component
    uri = workflow_resp.find_first('//workflow')['resource']
    component = Workflow.find(uri.split('/').last.to_i)

    # Check it was added to the family
    assert_includes family.contributable_entries.map { |e| e.contributable }, component

    # Check it was tagged
    assert component.component?

    # Check it's retrievable
    query_resp = rest_request(:get, 'components')
    assert_response(:success)
    assert_equal 1, query_resp.find('//workflow').size
    assert_equal uri, query_resp.find_first('//workflow')['resource']
  end


  test "can delete components" do
    login_as(:john)
    component = workflows(:component_workflow)
    component_uri = polymorphic_url(component)
    family_uri = polymorphic_url(packs(:component_family))

    # Store in triplestore
    TripleStore.instance.repo = {}
    TripleStore.instance.insert("", "<#{component_uri}>")

    # Check the component is there
    assert_equal 1, TripleStore.instance.repo.keys.size
    resp = rest_request(:get, 'components', nil, {'component-family' => family_uri})
    assert_response(:success)
    assert_equal 1, resp.find('//workflow').size

    # Delete the component
    rest_request(:delete, 'component', nil, {'id' => component.id})
    assert_response(:success)

    # Check it was removed from the triplestore
    assert_equal 0, TripleStore.instance.repo.keys.size

    # Shouldn't return any results
    resp = rest_request(:get, 'components', nil, {'component-family' => family_uri})
    assert_response(:success)
    assert_equal 0, resp.find('//workflow').size

    # Clean up
    TripleStore.instance.repo = {}
  end


  test "can't create component if family doesn't exist" do
    login_as(:john)

    # Upload a component workflow
    license_type = "by-sa"
    content_type = "application/vnd.taverna.t2flow+xml"
    content = Base64.encode64(File.read('test/fixtures/files/image_to_tiff_migration.t2flow'))
    assert_no_difference('Workflow.count') do
      rest_request(:post, 'component', "<?xml version='1.0'?>
        <workflow>
          <title>Test Component</title>
          <description>123</description>
          <component-family>http://www.example.com/families/123</component-family>
          <license-type>#{license_type}</license-type>
          <content-type>#{content_type}</content-type>
          <content>#{content}</content>
        </workflow>")
    end

    assert_response(404)
  end

  test "can't create component if family url points to non-family resource" do
    login_as(:john)

    # Upload a component workflow
    license_type = "by-sa"
    content_type = "application/vnd.taverna.t2flow+xml"
    content = Base64.encode64(File.read('test/fixtures/files/image_to_tiff_migration.t2flow'))
    assert_no_difference('Workflow.count') do
      rest_request(:post, 'component', "<?xml version='1.0'?>
        <workflow>
          <title>Test Component</title>
          <description>123</description>
          <component-family>#{polymorphic_url(packs(:pack_1))}</component-family>
          <license-type>#{license_type}</license-type>
          <content-type>#{content_type}</content-type>
          <content>#{content}</content>
        </workflow>")
    end

    assert_response(400)
  end

  test "can't create components in protected family" do
    login_as(:jane)

    # Upload a component workflow
    license_type = "by-sa"
    content_type = "application/vnd.taverna.t2flow+xml"
    content = Base64.encode64(File.read('test/fixtures/files/image_to_tiff_migration.t2flow'))
    family = packs(:protected_component_family)
    assert_no_difference('Workflow.count') do
      rest_request(:post, 'component', "<?xml version='1.0'?>
        <workflow>
          <title>Test Component</title>
          <description>123</description>
          <component-family>#{polymorphic_url(family)}</component-family>
          <license-type>#{license_type}</license-type>
          <content-type>#{content_type}</content-type>
          <content>#{content}</content>
        </workflow>")
    end

    assert_response(401)
  end

  test "can create component versions" do
    login_as(:john)

    # Set up
    component = workflows(:component_workflow)
    version_count = WorkflowVersion.count
    # Put in triplestore
    TripleStore.instance.repo = {}
    TripleStore.instance.insert("", "<#{polymorphic_url(component)}>")

    # Check its there
    resp = rest_request(:get, 'components')
    assert_response(:success)
    assert_equal 1, resp.find('//workflow').size
    assert_equal "", TripleStore.instance.repo["<#{polymorphic_url(component)}>"]

    # Post new version
    content = Base64.encode64(File.read('test/fixtures/files/image_to_tiff_migration.t2flow'))

    workflow_resp = rest_request(:post, 'component', "<?xml version='1.0'?>
      <workflow>
        <title>Test Component II</title>
        <description>456</description>
        <content>#{content}</content>
      </workflow>", {'id' => component.id})

    assert_response(:success)

    # Get the newly created component
    uri = workflow_resp.find_first('//workflow')['resource']
    component = Workflow.find(uri.split('/').last.to_i)

    # Check the response body contains the updated metadata
    assert_equal "2", workflow_resp.find_first('//workflow')['version']
    assert_equal 'Test Component II', workflow_resp.find_first('//title/text()').to_s

    # Check the version was created
    assert_equal version_count+1, WorkflowVersion.count
    assert_equal 'Test Component II', component.title

    # Check there's still only one component in the triplestore
    query_resp = rest_request(:get, 'components')
    assert_response(:success)
    assert_equal 1, query_resp.find('//workflow').size
    assert_equal uri, query_resp.find_first('//workflow')['resource']
    assert_not_equal "", TripleStore.instance.repo["<#{polymorphic_url(component)}>"]
  end

  test "can query components by family" do
    component_uri2 = polymorphic_url(workflows(:component_workflow2))
    component_uri = polymorphic_url(workflows(:component_workflow))
    private_component_uri = polymorphic_url(workflows(:private_component_workflow))
    family_uri = polymorphic_url(packs(:component_family))

    TripleStore.instance.repo = {}
    TripleStore.instance.insert("", "<#{component_uri2}>") # Not in the family
    TripleStore.instance.insert("", "<#{private_component_uri}>") # In the family, but not viewable
    TripleStore.instance.insert("", "<#{component_uri}>") # In the family

    # Should only return one result
    resp = rest_request(:get, 'components', nil, {'component-family' => family_uri})
    assert_response(:success)
    assert_equal 3, TripleStore.instance.repo.keys.size
    assert_equal 1, resp.find('//workflow').size
    assert_equal component_uri, resp.find_first('//workflow')['resource']

    # Clean up
    TripleStore.instance.repo = {}
  end

  test "component query only returns local results" do
    # Set up
    login_as(:john)

    uri = polymorphic_url(workflows(:component_workflow))

    TripleStore.instance.repo = {}
    TripleStore.instance.insert("", "<http://www.google.com/>")
    TripleStore.instance.insert("", "<http://www.example.com/workflows/456>")
    TripleStore.instance.insert("", "<#{uri}>")

    # Should only return one result
    resp = rest_request(:get, 'components', nil, {'prefixes' => '', 'query' => ''})
    assert_response(:success)
    assert_equal 3, TripleStore.instance.repo.keys.size
    assert_equal 1, resp.find('//workflow').size
    assert_equal uri, resp.find_first('//workflow')['resource']

    # Clean up
    TripleStore.instance.repo = {}
  end

  test "component query doesn't return private components" do
    # Set up
    TripleStore.instance.repo = {}
    TripleStore.instance.insert("", "<#{polymorphic_url(workflows(:private_component_workflow))}>")

    # Should only return one result
    resp = rest_request(:get, 'components', nil, {'prefixes' => '', 'query' => ''})
    assert_response(:success)
    assert_equal 1, TripleStore.instance.repo.keys.size
    assert_equal 0, resp.find('//workflow').size

    # Clean up
    TripleStore.instance.repo = {}
  end

  test "component query does return private components for authorized user" do
    # Set up
    login_as(:john)

    uri = polymorphic_url(workflows(:private_component_workflow))

    TripleStore.instance.repo = {}
    TripleStore.instance.insert("", "<#{uri}>")

    # Should only return one result
    resp = rest_request(:get, 'components', nil, {'prefixes' => '', 'query' => ''})
    assert_response(:success)
    assert_equal 1, TripleStore.instance.repo.keys.size
    assert_equal 1, resp.find('//workflow').size
    assert_equal uri, resp.find_first('//workflow')['resource']

    # Clean up
    TripleStore.instance.repo = {}
  end

  test "can get list of component profiles" do
    login_as(:john)

    profile_count = Blob.all.select { |b| b.component_profile? }.size

    resp = rest_request(:get, 'component-profiles')
    assert_response(:success)

    assert_equal profile_count, resp.find('//file').size
    profiles = resp.find('//file').map { |f| Blob.find(f['resource'].split('/').last.to_i) }
    assert_includes profiles, blobs(:component_profile)
  end

  test "can create component profile" do
    login_as(:john)

    # Get list of profiles first
    resp = rest_request(:get, 'component-profiles')
    assert_response(:success)
    profile_count = resp.find('//file').size

    content = Base64.encode64(File.read('test/fixtures/files/workflow_dilbert.xml'))
    body = %(
      <file>
        <title>Component Profile</title>
        <filename>profile.xml</filename>
        <description>It's for components</description>
        <content-type>application/vnd.taverna.component-profile+xml</content-type>
        <content>#{content}</content>
        <license-type>by-sa</license-type>
      </file>
    )

    resp = rest_request(:post, 'component-profile', body)
    assert_response(:success)

    uri = resp.find_first('//file')['resource']
    profile = Blob.find_by_id(uri.split('/').last.to_i)
    assert_not_nil profile
    assert_includes profile.tags.map {|t| t.name }, 'component profile'

    # Check new family returned in list
    resp = rest_request(:get, 'component-profiles')
    assert_response(:success)
    assert_equal profile_count+1, resp.find('//file').size
    assert_includes resp.find('//file').map {|f| f['resource']}, uri
  end

  test "can delete component profile that isn't used in any families" do
    login_as(:john)

    profile = blobs(:unused_component_profile)

    assert_difference('Blob.count', -1) do
      rest_request(:delete, 'component-profile', nil, 'id' => profile.id)
    end

    assert_response(:success)
  end

  test "can't delete component profile that is used" do
    login_as(:john)

    profile = blobs(:component_profile)

    assert_no_difference('Blob.count') do
      rest_request(:delete, 'component-profile', nil, 'id' => profile.id)
    end

    assert_response(400)
  end

  test "can get list of component families" do
    login_as(:john)

    family_count = Pack.all.select { |p| p.component_family? }.size

    resp = rest_request(:get, 'component-families')
    assert_response(:success)

    assert_equal family_count, resp.find('//pack').size
    families = resp.find('//pack').map { |f| Pack.find(f['resource'].split('/').last.to_i) }
    assert_includes families, packs(:component_family)
  end

  test "can create component family" do
    login_as(:john)

    family_count = Pack.all.select { |p| p.component_family? }.size

    body = %(
      <pack>
        <title>A Component Family</title>
        <description>It's for components</description>
        <component-profile>#{polymorphic_url(blobs(:component_profile))}</component-profile>
        <license-type>by-sa</license-type>
      </pack>
    )

    resp = rest_request(:post, 'component-family', body)
    assert_response(:success)

    uri = resp.find_first('//pack')['resource']
    family = Pack.find_by_id(uri.split('/').last.to_i)
    assert_not_nil family
    assert_includes family.tags.map {|t| t.name }, 'component family'

    resp = rest_request(:get, 'component-families')
    assert_response(:success)
    assert_equal family_count+1, resp.find('//pack').size
    assert_includes resp.find('//pack').map { |p| p['resource'] }, uri
  end

  test "can't create component family with missing profile uri" do
    login_as(:john)

    body = %(
      <pack>
        <title>A Component Family</title>
        <description>It's for components</description>
        <license-type>by-sa</license-type>
      </pack>
    )

    assert_no_difference('Pack.count') do
      rest_request(:post, 'component-family', body)
    end

    assert_response(400)
  end

  test "can't create component family with invalid profile uri" do
    login_as(:john)

    body = %(
      <pack>
        <title>A Component Family</title>
        <description>It's for components</description>
        <component-profile>http://www.example.com/profiles/241</component-profile>
        <license-type>by-sa</license-type>
      </pack>
    )

    assert_no_difference('Pack.count') do
      rest_request(:post, 'component-family', body)
    end

    assert_response(404)
  end


  test "can't create component family with profile uri pointing to non-profile resources" do
    login_as(:john)

    body = %(
      <pack>
        <title>A Component Family</title>
        <description>It's for components</description>
        <component-profile>#{polymorphic_url(blobs(:picture))}</component-profile>
        <license-type>by-sa</license-type>
      </pack>
    )

    assert_no_difference('Pack.count') do
      rest_request(:post, 'component-family', body)
    end

    assert_response(400)

    body = %(
      <pack>
        <title>A Component Family</title>
        <description>It's for components</description>
        <component-profile>#{polymorphic_url(workflows(:workflow_dilbert))}</component-profile>
        <license-type>by-sa</license-type>
      </pack>
    )

    assert_no_difference('Pack.count') do
      rest_request(:post, 'component-family', body)
    end

    assert_response(400)
  end

  test "can delete component family and components" do
    login_as(:john)

    family = packs(:protected_component_family)
    component_count = family.contributable_entries.select { |e| e.contributable_type == 'Workflow' && e.contributable.component? }.size

    assert_no_difference('Blob.count') do # Profile not deleted
    assert_difference('Workflow.count', -component_count) do # Components deleted
    assert_difference('Pack.count', -1) do # Family deleted
      rest_request(:delete, 'component-family', nil, 'id' => family.id)
    end
    end
    end

    assert_response(:success)
  end

  test "can delete component family after deleting a component inside it" do
    login_as(:john)
    component = workflows(:private_component_workflow)
    family = packs(:protected_component_family)

    assert_difference('Workflow.count', -1) do # Component deleted
      rest_request(:delete, 'workflow', nil, 'id' => component.id)
    end

    assert_response(:success)

    assert_no_difference('Blob.count') do # Profile not deleted
    assert_difference('Pack.count', -1) do # Family deleted
      rest_request(:delete, 'component-family', nil, 'id' => family.id)
    end
    end

    assert_response(:success)
  end

  test "can't delete component family containing other people's components" do
    login_as(:john)

    assert_no_difference('Blob.count') do
    assert_no_difference('Workflow.count') do
    assert_no_difference('Pack.count') do
      rest_request(:delete, 'component-family', nil, 'id' => packs(:communal_component_family).id)
    end
    end
    end

    assert_response(401)
  end

  test "can get a component" do
    component = workflows(:component_workflow)
    component_uri = polymorphic_url(component)
    resp = rest_request(:get, 'component', nil, 'id' => component.id)
    assert_response(:success)
    assert_equal component_uri, resp.find_first('//workflow')['resource']
  end

  test "can see component families in component description" do
    component = workflows(:component_workflow)
    component_uri = polymorphic_url(component)
    family_uri = polymorphic_url(packs(:component_family))
    resp = rest_request(:get, 'component', nil, 'id' => component.id, 'elements' => 'component-families')
    assert_response(:success)
    assert_equal component_uri, resp.find_first('//workflow')['resource']
    assert_equal 1, resp.find('//component-families/component-family').size
    assert_equal family_uri, resp.find_first('//component-families/component-family/text()').to_s
  end

  private

  def rest_request(method, uri, data = nil, query = {})
    @request.env['RAW_POST_DATA'] = data if data
    parameters = { :uri => uri, :format => "xml" }.merge(query)

    send(method, :process_request, parameters)

    LibXML::XML::Parser.string(@response.body).parse
  end
end
