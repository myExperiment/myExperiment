require File.dirname(__FILE__) + '/../test_helper'

class PackTest < ActiveSupport::TestCase
  fixtures :packs

  test "can mint DOI for pack" do
    p = packs(:doiable_pack)

    assert p.mint_doi
    assert_equal "#{Conf.doi_prefix}pack/#{p.id}", p.doi
    assert_equal "http://test.host/packs/#{p.id}", DataciteClient.instance.resolve(p.doi)
  end

  test "can't mint DOI for pack if an author's family/given names not set" do
    p = packs(:component_family)

    assert_raise RuntimeError do
      p.mint_doi
    end
    assert p.doi.blank?
    assert !DataciteClient.instance.resolve(p.doi)
  end
end
