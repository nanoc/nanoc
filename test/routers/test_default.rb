require 'test/helper'

class Nanoc3::Routers::DefaultTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_path_for_item_rep_with_default_rep
    # Create default router
    router = Nanoc3::Routers::Default.new(nil)

    # Get item
    item = Nanoc3::Item.new(
      'some content',
      { :filename => 'home', :extension => 'htm' },
      '/foo/'
    )
    item_rep = Nanoc3::ItemRep.new(item, :default)

    # Check
    assert_equal('/foo/home.htm', router.path_for_item_rep(item_rep))
  end

  def test_path_for_item_rep_with_custom_rep
    # Create default router
    router = Nanoc3::Routers::Default.new(nil)

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
    assert_equal('/foo/home-raw.htm', router.path_for_item_rep(item_rep))
  end

end
