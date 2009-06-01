# encoding: utf-8

require 'test/helper'

class Nanoc3::Routers::NoDirsTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_path_for_root_item_rep
    # Create no-dirs router
    router = Nanoc3::Routers::NoDirs.new(nil)

    # Create site
    site = mock

    # Get item
    item = Nanoc3::Item.new(
      'some content',
      { :filename => 'home', :extension => 'htm' },
      '/'
    )
    item_rep = Nanoc3::ItemRep.new(item, :default)

    # Check
    assert_equal('/home.htm', router.path_for_item_rep(item_rep))
  end

  def test_path_for_item_rep_with_default_rep
    # Create no-dirs router
    router = Nanoc3::Routers::NoDirs.new(nil)

    # Create site
    site = mock

    # Get item
    item = Nanoc3::Item.new(
      'some content',
      { :filename => 'home', :extension => 'htm' },
      '/foo/'
    )
    item_rep = Nanoc3::ItemRep.new(item, :default)

    # Check
    assert_equal('/foo.htm', router.path_for_item_rep(item_rep))
  end

  def test_path_for_item_rep_with_custom_rep
    # Create no-dirs router
    router = Nanoc3::Routers::NoDirs.new(nil)

    # Create site
    site = mock

    # Get item
    item = Nanoc3::Item.new(
      'some content',
      {
        :filename => 'home',
        :extension => 'htm'
      },
      '/foo/'
    )
    item_rep = Nanoc3::ItemRep.new(item, :raw)

    # Check
    assert_equal('/foo-raw.htm', router.path_for_item_rep(item_rep))
  end

end
