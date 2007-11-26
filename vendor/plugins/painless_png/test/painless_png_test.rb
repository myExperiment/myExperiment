unless defined?(RAILS_ROOT)
  RAILS_ROOT = ENV["RAILS_ROOT"] ||
    File.join(File.dirname(__FILE__), "../../../../")
end
require File.join(RAILS_ROOT, "test", "test_helper")
require File.join(File.dirname(__FILE__), "..", "init")
require 'ftools'

# Re-raise errors caught by the controller.
class TestController < ActionController::Base ; def rescue_action(e) raise e end; end

# Equip our test controller with an action that renders image tags inline
class TestController
  def index
    params[:src] ||= "painless_test.png"
    render :inline => "<%= image_tag '#{params[:src]}' -%>"
  end
end

# Let's test!
class PainlessPngTest < Test::Unit::TestCase
  
  LEGACY_BROWSERS = [
    'Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.0)',       # IE 5.5 on Windows 2000
    'Mozilla/4.0 (compatible; MSIE 6.0; MSN 2.5; Windows 98)',  # IE 5.5 on Windows 98
    'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)',  # IE6 on Windows XP SP2
  ]
  
  CURRENT_BROWSERS = [
    # Firefox respectively on Windows XP, Debian Linux and 
    'Mozilla/5.0 (Windows; U; Windows NT 5.1; nl; rv:1.8) Gecko/20051107 Firefox/1.5',
    'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.3) Gecko/20060426 Firefox/1.5.0.3',
    'Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.0.7) Gecko/20060909 Firefox/1.5.0.7',
    # Opera on Windows XP
    'Opera/9.02 (Windows NT 5.1; U; en)',
    # Safari
    'Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en) AppleWebKit/418.9 (KHTML, like Gecko) Safari/419.3'
  ]
  
  def setup
    @controller = TestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @page = ActionView::Base.new
    @page.request = @request
    
    @test_png_orig = File.join(RAILS_ROOT, "vendor", "plugins", "painless_png", "painless_test.png")
    @test_png = File.join(RAILS_ROOT, "public", "images", "painless_test.png")
    File.copy(@test_png_orig, @test_png)
  end
  
  def teardown
    File.delete(@test_png)
  end
  
  # Make sure PNG sizes are determined correctly
  def test_png_size_determined_correctly
    assert_equal [120, 175], @page.get_png_size(@test_png)
  end
  
  # Make sure legacy browsers are detected as such
  def test_legacy_browser_detected
    for browser in LEGACY_BROWSERS
      @request.user_agent = browser
      assert @page.legacy_browser?
    end
  end
  
  # Make sure current browsers are detected as such
  def test_current_browsers_detected
    for browser in CURRENT_BROWSERS
      @request.user_agent = browser
      assert ! @page.legacy_browser?
    end
  end
  
  # Make sure that the images are replaced by DIVs on legacy browsers
  def test_on_legacy_browsers
    for legacy_browser in LEGACY_BROWSERS
      @request.user_agent = legacy_browser
      get :index
      assert_response :success
      assert_select 'div[style*=filter:progid:DXImageTransform.Microsoft.AlphaImageLoader]'
      assert_select 'div[style*=height:175px]'
      assert_select 'div[style*=width:120px]'
    end
  end
  
  # Make sure the images are left untouched on current browsers
  def test_on_current_browsers
    for current_browser in CURRENT_BROWSERS
      @request.user_agent = current_browser
      get :index
      assert_response :success
      assert_select 'img[src*=painless_test.png]'
    end
  end
  
  # Make sure it also works when the "source" argument doesn't contain
  # an extension (in which case Rails assumes it's a PNG).
  # TODO: this feature will soon be deprecated in Rails
  def test_also_works_without_png_extension
    @request.user_agent = CURRENT_BROWSERS[0]
    get :index, :src => "painless_test"
    assert_response :success
    assert_select "img[src*=painless_test.png]"
    
    @request.user_agent = LEGACY_BROWSERS[0]
    get :index, :src => "painless_test"
    assert_response :success
    assert_select 'div[style*=filter:progid:DXImageTransform.Microsoft.AlphaImageLoader]'
    assert_select 'div[style*=height:175px]'
    assert_select 'div[style*=width:120px]'
  end
  
  # Make sure non-PNG images remain untouched
  def test_non_pngs_unaffacted
    for image in %w(test.jpg test.jpeg test.gif test.bmp)
      get :index, :src => image
      assert_response :success
      extension = image.gsub(/^.*\./, '')
      assert_select "img[src*=test.#{extension}]"
    end
  end
  
end
