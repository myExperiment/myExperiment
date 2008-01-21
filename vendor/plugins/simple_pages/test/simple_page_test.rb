require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + '/../../../../config/environment')
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')
require File.expand_path(File.dirname(__FILE__)) + '/../app/controllers/simple_pages_controller'

class SimplePageTest < Test::Unit::TestCase
  def test_model_validation
    simple_page = SimplePage.create
    assert !simple_page.errors.empty?
    assert_not_nil simple_page.errors.on(:filename)
    assert_not_nil simple_page.errors.on(:title)
    simple_page.update_attributes(:filename => 'duplicate', :title => 'some title')
    simple_page = SimplePage.create(:filename => 'duplicate', :title => 'some title')
    assert_not_nil simple_page.errors.on(:filename)
    assert_not_nil simple_page.errors.on(:title)
  end
end
