# encoding: utf-8

class Nanoc::Helpers::BreadcrumbsTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  include Nanoc::Helpers::Breadcrumbs

  def test_breadcrumbs_trail_at_root
    # Mock item
    @item = mock
    @item.stubs(:identifier).returns('/')
    @items = [ @item ]

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
    parent.stubs(:identifier).returns('/')
    @item = mock
    @item.stubs(:identifier).returns('/foo/')
    @items = [ parent, @item ]

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
    grandparent.stubs(:identifier).returns('/')
    parent = mock
    parent.stubs(:identifier).returns('/foo/')
    @item = mock
    @item.stubs(:identifier).returns('/foo/bar/')
    @items = [ grandparent, parent, @item ]

    # Build trail
    trail = breadcrumbs_trail

    # Check
    assert_equal(
      [ grandparent, parent, @item ],
      trail
    )
  end

  def test_breadcrumbs_trail_with_nils
    # Mock item
    grandparent = mock
    grandparent.stubs(:identifier).returns('/')
    @item = mock
    @item.stubs(:identifier).returns('/foo/bar/')
    @items = [ grandparent, @item ]

    # Build trail
    trail = breadcrumbs_trail

    # Check
    assert_equal(
      [ grandparent, nil, @item ],
      trail
    )
  end

end
