require File.dirname(__FILE__) + '/../test_helper'

class ProfileTest < ActiveSupport::TestCase
  fixtures :profiles

  test 'can have https in website' do
    profile = profiles(:john_profile)

    profile.website = 'https://example.com'

    assert profile.save
    assert_equal 'https://example.com', profile.reload.website
  end

  test 'can have http in website' do
    profile = profiles(:john_profile)

    profile.website = 'http://example.com'

    assert profile.save
    assert_equal 'http://example.com', profile.reload.website
  end

  test 'cannot have invalid scheme in website' do
    profile = profiles(:john_profile)

    profile.website = 'ftp://example.com'

    refute profile.save
    assert_not_equal 'ftp://example.com', profile.reload.website
  end
end
