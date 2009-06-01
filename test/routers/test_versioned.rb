# encoding: utf-8

require 'test/helper'

class Nanoc3::Routers::VersionedTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_path_for_item_rep_with_default_rep
    # Create versioned router
    router = Nanoc3::Routers::Versioned.new(nil)

    # Create site
    site = mock

    # Get item
    item = Nanoc3::Item.new(
      'some content',
      {
        :filename   => 'home',
        :extension  => 'htm'
      },
      '/foo/'
    )
    item_rep = Nanoc3::ItemRep.new(item, :default)

    # Check
    assert_equal('/foo/home.htm', router.path_for_item_rep(item_rep))
  end

  def test_path_for_item_rep_with_default_rep_with_version
    # Create versioned router
    router = Nanoc3::Routers::Versioned.new(nil)

    # Create site
    site = mock

    # Get item
    item = Nanoc3::Item.new(
      'some content',
      {
        :filename   => 'home',
        :extension  => 'htm',
        :version    => 123
      },
      '/foo/'
    )
    item_rep = Nanoc3::ItemRep.new(item, :default)

    # Check
    assert_equal('/foo/home-v123.htm', router.path_for_item_rep(item_rep))
  end

  def test_path_for_item_rep_with_custom_rep_without_version
    # Create versioned router
    router = Nanoc3::Routers::Versioned.new(nil)

    # Create site
    site = mock

    # Get item
    item = Nanoc3::Item.new(
      'some content',
      {
        :filename   => 'home',
        :extension  => 'htm'
      },
      '/foo/'
    )
    item_rep = Nanoc3::ItemRep.new(item, :raw)

    # Check
    assert_equal('/foo/home-raw.htm', router.path_for_item_rep(item_rep))
  end

  def test_path_for_item_rep_with_custom_rep_with_version
    # Create versioned router
    router = Nanoc3::Routers::Versioned.new(nil)

    # Create site
    site = mock

    # Get item
    item = Nanoc3::Item.new(
      'some content',
      {
        :filename   => 'home',
        :extension  => 'htm',
        :version    => 123
      },
      '/foo/'
    )
    item_rep = Nanoc3::ItemRep.new(item, :raw)

    # Check
    assert_equal('/foo/home-raw-v123.htm', router.path_for_item_rep(item_rep))
  end

end
