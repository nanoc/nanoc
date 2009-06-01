# encoding: utf-8

require 'test/helper'

class Nanoc3::Helpers::BreadcrumbsTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  include Nanoc3::Helpers::Breadcrumbs

  def test_breadcrumbs_trail_with_0_parents
    # Mock item
    @item = mock
    @item.expects(:parent).returns(nil)

    # Build trail
    trail = breadcrumbs_trail

    # Check
    assert_equal(
      [ @item ],
      trail
    )
  end

  def test_breadcrumbs_trail_with_1_parent
    # Mock item
    parent = mock
    parent.expects(:parent).returns(nil)
    @item = mock
    @item.expects(:parent).returns(parent)

    # Build trail
    trail = breadcrumbs_trail

    # Check
    assert_equal(
      [ parent, @item ],
      trail
    )
  end

  def test_breadcrumbs_trail_with_many_parents
    # Mock item
    grandparent = mock
    grandparent.expects(:parent).returns(nil)
    parent = mock
    parent.expects(:parent).returns(grandparent)
    @item = mock
    @item.expects(:parent).returns(parent)

    # Build trail
    trail = breadcrumbs_trail

    # Check
    assert_equal(
      [ grandparent, parent, @item ],
      trail
    )
  end

end
